
import 'package:unittest/unittest.dart';

import '../lib/src/builder/vars_generator.dart';

void main() {
  group("Variables extractor", () {
    test("extracts without throwing", () {
      String code = """
        /// Comment.
        SpaceshipMock bodega; 
        bool isEngineer, isMedic;// Another comment.
        /* Third comment. */
        int maxPhysicalPoints;
        var number;
        """;
      var generator = new VarsGenerator();
      expect(() => generator.addSource(code), returnsNormally);
      print(generator.createExtractMethod());
      print(generator.createPopulateMethod());
    });

    test("extracts all variables", () {
      String code = """
        SpaceshipMock bodega; 
        bool isEngineer, isMedic;
        int maxPhysicalPoints;
        var number;
        """;
      var generator = new VarsGenerator();
      generator.addSource(code);
      expect(generator.variables.length, 5);
    });

    test("extracts type", () {
      String code = """
        SpaceshipMock bodega; 
        var number;
        """;
      var generator = new VarsGenerator();
      generator.addSource(code);
      expect(generator.variables.first.type, "SpaceshipMock");
      expect(generator.variables.last.type, null);
    });

    test("throws on bad code", () {
      String code = """
        SpaceshipMock bodega.;
        """;
      var generator = new VarsGenerator();
      expect(() => generator.addSource(code), throwsArgumentError);
    });

    test("throws with duplicate variables in one code block", () {
      String code = """
        SpaceshipMock bodega;
        int something;
        bool bodega;
        """;
      var generator = new VarsGenerator();
      expect(() => generator.addSource(code), throwsArgumentError);
    });

    test("throws with duplicate variables in different blocks", () {
      String code = """
        SpaceshipMock bodega;
        int something;
        """;
      var generator = new VarsGenerator();
      generator.addSource(code);
      String additionalCode = """
        bool bodega;
        """;
      expect(() => generator.addSource(additionalCode), throwsArgumentError);
    });

    test("generates valid methods", () {
      String code = """
        SpaceshipMock bodega;
        int something;
        var number;
        """;

      String extractMethod = """
  void extractStateFromVars() {
    bodega = vars["bodega"] as SpaceshipMock;
    something = vars["something"] as int;
    number = vars["number"];
  }
""";

      String populateMethod = """
  void populateVarsFromState() {
    vars["bodega"] = bodega;
    vars["something"] = something;
    vars["number"] = number;
  }
""";

      var generator = new VarsGenerator();
      generator.addSource(code);
      String generatedExtractMethod = generator.createExtractMethod();
      expect(generatedExtractMethod.trim(), extractMethod.trim());
      String generatedPopulateMethod = generator.createPopulateMethod();
      expect(generatedPopulateMethod.trim(), populateMethod.trim());
    });
  });

}