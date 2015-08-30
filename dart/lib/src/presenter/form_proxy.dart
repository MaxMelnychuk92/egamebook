library egb_form_proxy;

import "../shared/form.dart";
import "package:jsonml/jsonml2html5lib.dart";
import 'dart:async';
import 'package:egamebook/src/shared/message.dart';

/**
 * Library that takes the Map generated by [Form.toMap()] and parses it. The
 * [EgbPresenter] is then responsible for creating the actual form (for example,
 * by adding DOM elements to page) and listening to user input.
 */
class FormProxy extends FormBase implements BlueprintWithUiRepresentation {
  /// Creates new FormProxy from a [map].
  FormProxy.fromMap(Map<String, Object> map) {
    assert((map["jsonml"] as List)[0] == "Form");
    submitText = (map["jsonml"] as List)[1]["submitText"];
    createElementsFromJsonML(map["jsonml"]);
    FormConfiguration values = new FormConfiguration.fromMap(map["values"]);
    allFormElementsBelowThisOne.forEach((FormElement element) {
      Map<String, Object> elementValues = values.getById(element.id);
      if (elementValues != null) {
        element.updateFromMap(elementValues);
      }
    });
  }

  /// Creates new FormProxy from [EgbMessage].
  FormProxy.fromMessage(EgbMessage msg)
  : this.fromMap(msg.mapContent);

  /// Recursively creates [UiElement] from a given map of [UiElementBuilder]
  /// builders.
  UiElement buildUiElements(Map<String, UiElementBuilder> builders) {
    return _recursiveCreateUiElement(builders, this);
  }

  /// Mapping from [FormElement] (blueprint) to actual UI representations.
  UiElement uiElement;

  /// Recursively creates [UiElement] from a given map of [UiElementBuilder]
  /// builders with help of [BlueprintWithUiRepresentation] element.
  UiElement _recursiveCreateUiElement(Map<String, UiElementBuilder> builders,
                        BlueprintWithUiRepresentation element) {
    if (!builders.containsKey(element.localName)) {
      throw new UnimplementedError("The tag '${element.localName}' is not "
          "among the implemented presenter builders "
          "(${builders.keys.join(', ')}).");
    }
    UiElement uiElement = builders[element.localName](element);
    element.uiElement = uiElement;
    if (uiElement.onChange != null) {
      var subscription = uiElement.onChange.listen((_) {
        // Send the state to the Scripter.
        CurrentState state = _createCurrentState(element);
        _streamController.add(state);
      });
      _onChangeSubscriptions.add(subscription);
    }
    for (BlueprintWithUiRepresentation child in element.formElementChildren) {
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
      Map<String, Object> map = config.getById(element.id);
      if (map != null) {
        element.updateFromMap(map);
        (element as BlueprintWithUiRepresentation).uiElement.update();
      }
    });
    if (unsetWaitingForUpdate) {
      allFormElementsBelowThisOne.where((element) => element is Input)
      .forEach((element) {
        (element as BlueprintWithUiRepresentation).uiElement.waitingForUpdate =
            false;
      });
    }
  }

  /// Utility function that gathers [CurrentState] values from the form.
  /// When [submitted] is [:true:], the form gets disabled. When
  /// [setWaitingForUpdate] is [:true:], all elements are temporarily 'disabled'
  /// in order to wait for update from Scripter.
  CurrentState _createCurrentState(BlueprintWithUiRepresentation elementTouched,
                                   [bool setWaitingForUpdate=true]) {
    CurrentState state = new CurrentState();
    allFormElementsBelowThisOne.where((element) => element is Input)
    .forEach((element) {
      state.add(element.id, (element as BlueprintWithUiRepresentation).uiElement.current);
      if (setWaitingForUpdate) {
        (element as BlueprintWithUiRepresentation).uiElement.waitingForUpdate = true;
      }
    });
    if (setWaitingForUpdate) {
      this.uiElement.waitingForUpdate = true;
    }
    // Events from the Form UiElement itself are Submit events. And events from
    // submit buttons are also Submit events.
    state.submitted = elementTouched is SubmitButtonBase || elementTouched is FormBase;
    if (state.submitted) {
      this.uiElement.disabled = true;
      state.submitterId = elementTouched.id;
      _cancelSubscriptions();
    }
    return state;
  }

  /// Set of on change [StreamSubscription]s.
  Set<StreamSubscription> _onChangeSubscriptions =
      new Set<StreamSubscription>();
  /// Cancels all [_onChangeSubscriptions].
  void _cancelSubscriptions() {
    _onChangeSubscriptions.forEach((StreamSubscription s) => s.cancel());
  }

  /// [CurrentState] stream controller.
  StreamController<CurrentState> _streamController =
        new StreamController<CurrentState>();
  /// Getter for a [Stream] from stream controller.
  Stream<CurrentState> get stream => _streamController.stream;

  /// Creates [PresenterForm] from provided [jsonml] and adds its children
  /// elements into FormProxy [children] elements.
  void createElementsFromJsonML(List<Object> jsonml) {
    PresenterForm node = decodeToHtml5Lib(jsonml, customTags: customTagHandlers,
        unsafe: true);
    id = node.id;
    children.addAll(node.children);
  }
}

/// UI element builder typedef.
typedef UiElement UiElementBuilder(FormElement elementBlueprint);

/// It is an abstract blueprint class which contains also the UI representation
/// of Element - [UiElement].
abstract class BlueprintWithUiRepresentation extends FormElement {
  /// UI representation of element.
  UiElement uiElement;

  /// Creates new BlueprintWithUiRepresentation of given [elementClass].
  BlueprintWithUiRepresentation(String elementClass) : super(elementClass);
}

/// Base class for UI elements. It is a UI representation of element.
///
/// This class is used as a base class for [HtmlUiElement].
abstract class UiElement {
  /// The same as the subclass's blueprint, but not typed to a particular
  /// FormElement subtype. This is just convenience, and probably could be
  /// solved more elegantly.
  FormElement _blueprint;
  /// Creates new UiElement with form element [_blueprint].
  UiElement(this._blueprint);

  /// Updates the UiElement after the blueprint is changed. Sets
  /// [waitingForUpdate] back to [:false:].
  void update() {
    waitingForUpdate = false;
    disabled = _blueprint.disabledOrInsideDisabledParent;
    hidden = _blueprint.hidden;
  }

  /// Fired every time user interacts with Element and changes something.
  Stream get onChange;

  /// Setter for disabled.
  set disabled(bool value);
  /// Getter for disabled.
  bool get disabled;

  /// Setter for hidden.
  set hidden(bool value);
  /// Getter for hidden.
  bool get hidden;

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
  /// Append child method. Concrete implementation is in subclass.
  void appendChild(Object childUiRepresentation);
}

/// Maps [FormElement.elementClass] name to a function that takes the JSON
/// objects and returns.
Map<String, CustomTagHandler> customTagHandlers = {
  FormBase.elementClass: (Object jsonObject) {
    Map attributes = _getAttributesFromJsonML(jsonObject);
    return new PresenterForm(attributes["id"]);
  },
  FormSection.elementClass: (Object jsonObject) {
    Map attributes = _getAttributesFromJsonML(jsonObject);
    return new PresenterFormSection(attributes["name"], attributes["id"]);
  },
  SubmitButtonBase.elementClass: (Object jsonObject) {
    Map attributes = _getAttributesFromJsonML(jsonObject);
    return new PresenterSubmitButton(attributes["name"], attributes["id"]);
  },
  CheckboxInputBase.elementClass: (Object jsonObject) {
      Map attributes = _getAttributesFromJsonML(jsonObject);
      return new PresenterCheckboxInput(attributes["name"], attributes["id"]);
  },
  RangeInputBase.elementClass: (Object jsonObject) {
    Map attributes = _getAttributesFromJsonML(jsonObject);
    return new PresenterRangeInput(attributes["name"], attributes["id"]);
  },
  RangeOutputBase.elementClass: (Object jsonObject) {
    Map attributes = _getAttributesFromJsonML(jsonObject);
    return new PresenterRangeOutput(attributes["name"], attributes["id"]);
  },
  TextOutputBase.elementClass: (Object jsonObject) {
    Map attributes = _getAttributesFromJsonML(jsonObject);
    return new PresenterTextOutput(attributes["id"]);
  },
  MultipleChoiceInputBase.elementClass: (Object jsonObject) {
    Map attributes = _getAttributesFromJsonML(jsonObject);
    return new PresenterMultipleChoiceInput(attributes["name"],
        attributes["id"]);
  },
  OptionBase.elementClass: (Object jsonObject) {
    Map attributes = _getAttributesFromJsonML(jsonObject);
    return new PresenterOption(attributes["text"],
        attributes["selected"] == "true", attributes["id"]);
  }
};

/// Returns Map of attributes from provided JsonML.
Map<String, Object> _getAttributesFromJsonML(Object jsonObject) {
  // A JsonML element has it's attribute on the second position. Ex.:
  // <a href="#"></a> is ["a", {"href": "#"}].
  return (jsonObject as List)[1] as Map<String, Object>;
}

/// Class PresenterForm is a [FormBase] which wraps presenter form element.
///
/// It is used for setting of [FormProxy.children] elements to its
/// [PresenterForm.children] elements when retrieved and decoded from JsonML
/// in [FormProxy.createElementsFromJsonML].
class PresenterForm extends FormBase {
  /// Creates new PresenterForm with [id].
  PresenterForm(String id) {
    this.id = id;
  }
}

/// Class PresenterFormSection is a [FormSection] which contains also the UI
/// representation of element [UiElement].
class PresenterFormSection extends FormSection
    implements BlueprintWithUiRepresentation {
  /// Creates new PresenterFormSection with a given [name] and [id].
  PresenterFormSection(String name, String id) : super(name) {
    this.id = id;
  }

  /// UI representation of element.
  UiElement uiElement;
}

/// Class PresenterSubmitButton is a [SubmitButtonBase] which contains also the
/// UI representation of element [UiElement].
class PresenterSubmitButton extends SubmitButtonBase
    implements BlueprintWithUiRepresentation {
  /// Creates new PresenterSubmitButton with a given [name] and [id].
  PresenterSubmitButton(String name, String id) : super(name) {
    this.id = id;
  }

  /// UI representation of element.
  UiElement uiElement;
}

/// Class PresenterCheckboxInput is a [CheckboxInputBase] which contains also
/// the UI representation of element [UiElement].
class PresenterCheckboxInput extends CheckboxInputBase
    implements BlueprintWithUiRepresentation {
  /// Creates new PresenterCheckboxInput with a given [name] and [id].
  PresenterCheckboxInput(String name, String id) : super(name) {
    this.id = id;
  }

  /// UI representation of element.
  UiElement uiElement;
}

/// Class PresenterRangeInput is a [RangeInputBase] which contains also the UI
/// representation of element [UiElement] and its String representation
/// [currentStringRepresentation].
class PresenterRangeInput extends RangeInputBase
    implements StringRepresentationHolder, BlueprintWithUiRepresentation {
  /// Creates new PresenterRangeInput with a given [name] and [id].
  PresenterRangeInput(String name, String id) : super(name) {
    this.id = id;
  }
  /// The String representation. This is computed on the [EgbScripter] side
  /// and can be, for example, something like "90%" for [:0.9:] (percentage) or
  /// "intelligent" for [:120:] (IQ).
  String currentStringRepresentation;

  /// Updates from a Map representation in a [map].
  @override
  void updateFromMap(Map<String, Object> map) {
    super.updateFromMap(map);
    currentStringRepresentation = map["__string__"];
  }

  /// UI representation of element.
  UiElement uiElement;
}

/// Class PresenterRangeOutput is a [RangeOutputBase] which contains also the UI
/// representation of element [UiElement] and its String representation
/// [currentStringRepresentation].
class PresenterRangeOutput extends RangeOutputBase
    implements StringRepresentationHolder, BlueprintWithUiRepresentation {
  /// Creates new PresenterRangeOutput with a given [name] and [id].
  PresenterRangeOutput(String name, String id) : super(name) {
    this.id = id;
  }
  /// Current String representation.
  String currentStringRepresentation;

  /// Updates from a Map representation in a [map].
  @override
  void updateFromMap(Map<String, Object> map) {
    super.updateFromMap(map);
    currentStringRepresentation = map["__string__"];
  }

  /// UI representation of element.
  UiElement uiElement;
}

/// Class PresenterTextOutput is a [TextOutputBase] which contains also the UI
/// representation of element [UiElement].
class PresenterTextOutput extends TextOutputBase
    implements BlueprintWithUiRepresentation {
  /// Creates new PresenterTextOutput with a given [id].
  PresenterTextOutput(String id) : super() {
    this.id = id;
  }

  /// UI representation of element.
  UiElement uiElement;
}

/// Class PresenterMultipleChoiceInput is a [MultipleChoiceInputBase] which
/// contains also the UI representation of element [UiElement].
class PresenterMultipleChoiceInput extends MultipleChoiceInputBase
    implements BlueprintWithUiRepresentation {
  /// Creates new PresenterMultipleChoiceInput with a given [name] and [id].
  PresenterMultipleChoiceInput(String name, String id) : super(name) {
    this.id = id;
  }

  /// UI representation of element.
  UiElement uiElement;
}

/// Class PresenterOption is an [OptionBase] which contains also the UI
/// representation of element [UiElement].
class PresenterOption extends OptionBase
    implements BlueprintWithUiRepresentation {
  /// Creates new PresenterOption with a given [text], if [selected] and [id].
  PresenterOption(String text, bool selected, String id) :
    super(text, selected: selected) {
    this.id = id;
  }

  /// UI representation of element.
  UiElement uiElement;
}