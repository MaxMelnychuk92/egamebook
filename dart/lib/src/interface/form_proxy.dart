library egb_form_proxy;

import "../shared/form.dart";
import 'package:html5lib/dom.dart' as html5lib;
import "package:jsonml/jsonml2html5lib.dart";
import 'dart:async';

/**
 * Library that takes the Map generated by [Form.toMap()] and parses it. The
 * [EgbInterface] is then responsible for creating the actual form (for example,
 * by adding DOM elements to page) and listening to user input.
 */
class FormProxy extends FormBase {
  FormProxy.fromMap(Map<String,Object> map) {
    assert((map["jsonml"] as List)[0] == "Form");
    submitText = (map["jsonml"] as List)[1]["submitText"];
    createElementsFromJsonML(map["jsonml"]);
    FormConfiguration values = new FormConfiguration.fromMap(map["values"]);
    allFormElementsBelowThisOne.forEach((FormElement element) {
      Map<String,Object> elementValues = values.getById(element.id);
      if (elementValues != null) {
        (element as UpdatableByMap).updateFromMap(elementValues);
      }
    });
  }
  
  UiElement buildUiElements(Map<String,UiElementBuilder> builders) {
    return _recursiveCreateUiElement(builders, this);
  }
  
  Map<FormElement,UiElement> elementsMap = new Map<FormElement,UiElement>();
  UiElement _recursiveCreateUiElement(Map<String,UiElementBuilder> builders, 
                        FormElement element) {
    if (!builders.containsKey(element.localName)) {
      throw new UnimplementedError("The tag '${element.localName}' is not "
          "among the implemented interface builders "
          "(${builders.keys.join(', ')}).");
    }
    UiElement uiElement = builders[element.localName](element);
    elementsMap[element] = uiElement;
    if (uiElement.onInput != null) {
      uiElement.onInput.listen((_) {
        // Send the state to the Scripter.
        CurrentState state = _createCurrentState(setWaitingForUpdate: true,
            // Events from the Form UiElement itself are Submit events.
            submitted: uiElement == elementsMap[this]);
        _streamController.add(state);
      });
    }
    for (FormElement child in element.formElementChildren) {
      UiElement childUiElement = _recursiveCreateUiElement(builders, child);
      uiElement.appendChild(childUiElement.uiRepresentation);
    }
    return uiElement;
  }
  
  /// Updates all elements according to the provided [config]. If 
  /// [unsetWaitingForUpdate] is not [:true:] (default), the elements will stay
  /// in the [UiElement.waitingForUpdate] state (i.e., disabled).
  void update(FormConfiguration config, {bool unsetWaitingForUpdate: true}) {
    allFormElementsBelowThisOne.where((element) => element is UpdatableByMap)
    .forEach((FormElement element) {
      Map<String,Object> map = config.getById(element.id);
      if (map != null) {
        (element as UpdatableByMap).updateFromMap(map);
        elementsMap[element].update();
      }
    });
    if (unsetWaitingForUpdate) {
      allFormElementsBelowThisOne.where((element) => element is Input)
      .forEach((element) {
        elementsMap[element].waitingForUpdate = false;
      });
    }
  }
  
  /// Utility function that gathers values from the form. When [submitted] is
  /// [:true:], the form gets disabled. When [setWaitingForUpdate] is [:true:], 
  /// all elements are temporarily 'disabled' in order to wait for update from
  /// Scripter.
  CurrentState _createCurrentState({bool submitted: false, 
    bool setWaitingForUpdate: false}) {
    CurrentState state = new CurrentState();
    allFormElementsBelowThisOne.where((element) => element is Input)
    .forEach((element) {
      state.add(element.id, (elementsMap[element]).current);
      if (setWaitingForUpdate) {
        elementsMap[element].waitingForUpdate = true;
      }
    });
    if (setWaitingForUpdate) {
      elementsMap[this].waitingForUpdate = true;
    }
    if (submitted) {
      elementsMap[this].disabled = true;
    }
    state.submitted = submitted;
    return state;
  }
  
  StreamController<CurrentState> _streamController = 
        new StreamController<CurrentState>();
    Stream<CurrentState> get stream => _streamController.stream;
  
  void createElementsFromJsonML(List<Object> jsonml) {
    InterfaceForm node = decodeToHtml5Lib(jsonml, customTags: customTagHandlers,
        unsafe: true);
    children.addAll(node.children);
  }
}

typedef UiElement UiElementBuilder(FormElement elementBlueprint);

abstract class UiElement {
  UiElement(FormElement elementBlueprint);
  /// Updates the UiElement after the blueprint is changed. Sets
  /// [waitingForUpdate] back to [:false:].
  void update();
  /// Fired every time user interacts with Element and changes something.
  Stream get onInput;
  set disabled(bool value);
  bool get disabled;
  /// This is set to [:true:] after the user has interacted with the form and
  /// each [UiElement] in it should be disabled until [update] is called. This
  /// prevents user form setting the form's inputs into an invalid state.
  /// ([EgbScripter] always has a chance to act first, changing values,
  /// hiding inputs, disabling ranges, etc.)
  /// 
  /// This can be manifested the same way as [disabled], but is automatically
  /// called on all elements and is meant to be set to false after [EgbScripter]
  /// has had a chance to react to player's input. It shouldn't override
  /// [disabled] state.
  bool waitingForUpdate;
  /// The current value of the UiElement. Only getter, because the values are
  /// set through element blueprint and by calling [update].
  Object get current;
  /// This is the representation of the object in the UI. For HTML, this would
  /// be the [DivElement] that encompasses the [Form], or the [ParagraphElement]
  /// that materializes the [TextOutput]. 
  Object get uiRepresentation;
  void appendChild(Object childUiRepresentation);
}

/// Maps [FormElement.elementClass] name to a function that takes the JSON
/// objects and returns 
Map<String,CustomTagHandler> customTagHandlers = {
  FormBase.elementClass: (_) => new InterfaceForm(),
  FormSection.elementClass: (Object jsonObject) {
    Map attributes = _getAttributesFromJsonML(jsonObject);
    return new InterfaceFormSection(attributes["name"], attributes["id"]);
  },
  BaseRangeInput.elementClass: (Object jsonObject) {
    Map attributes = _getAttributesFromJsonML(jsonObject);
    return new InterfaceRangeInput(attributes["name"], attributes["id"]);
  },
  BaseRangeOutput.elementClass: (Object jsonObject) {
    Map attributes = _getAttributesFromJsonML(jsonObject);
    return new InterfaceRangeOutput(attributes["name"], attributes["id"]);
  },
  BaseTextOutput.elementClass: (Object jsonObject) {
    Map attributes = _getAttributesFromJsonML(jsonObject);
    return new InterfaceTextOutput(attributes["id"]);
  }
};

Map<String,Object> _getAttributesFromJsonML(Object jsonObject) {
  // A JsonML element has it's attribute on the second position. Ex.: 
  // <a href="#"></a> is ["a", {"href": "#"}].
  return (jsonObject as List)[1] as Map<String,Object>;
}

class InterfaceForm extends FormBase {
}

class InterfaceFormSection extends FormSection {
  InterfaceFormSection(String name, String id) : super(name) {
    this.id = id;
  }
}

class InterfaceRangeInput extends BaseRangeInput implements StringRepresentationHolder {
  InterfaceRangeInput(String name, String id) : super(name) {
    this.id = id;
  }
  /// The string representation. This is computed on the [EgbScripter] side
  /// and can be, for example, something like "90%" for [:0.9:] (percentage) or 
  /// "intelligent" for [:120:] (IQ).
  String currentStringRepresentation;
  
  @override
  void updateFromMap(Map<String, Object> map) {
    super.updateFromMap(map);
    currentStringRepresentation = map["__string__"];
  }
}

class InterfaceRangeOutput extends BaseRangeOutput implements StringRepresentationHolder {
  InterfaceRangeOutput(String name, String id) : super(name) {
    this.id = id;
  }
  String currentStringRepresentation;
  
  @override
  void updateFromMap(Map<String, Object> map) {
    super.updateFromMap(map);
    currentStringRepresentation = map["__string__"];
  }
}

class InterfaceTextOutput extends BaseTextOutput {
  InterfaceTextOutput(String id) : super() {
    this.id = id;
  }
}