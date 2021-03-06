within ;
package ExternalMemoryLib
  package Functions
    "This package wraps the actual external functions and tries to force the compiler to treat the functions as dynamic functions."
    function setReal
      input ExternalMemoryLib.ExternalMemoryReal arr;
      input Integer idx;
      input Real value;
      input Real timeIn;
    algorithm
      if timeIn>0 then
        ExternalMemoryLib.ExternalMemory_.setRealValueAt(arr, idx-1, value);
      else
        ExternalMemoryLib.ExternalMemory_.setRealValueAt(arr, idx-1, value);
      end if;
                            annotation(__ModelicaAssociation_Impure=true);
    end setReal;

    function setRealRange
      input ExternalMemoryLib.ExternalMemoryReal arr;
      input Integer idx;
      input Integer size;
      input Real[size] valueArr;
      input Real timeIn;
    algorithm
      if timeIn>0 then
        ExternalMemoryLib.ExternalMemory_.setRealRangeAt(arr, idx-1, size, valueArr);
      else
        ExternalMemoryLib.ExternalMemory_.setRealRangeAt(arr, idx-1, size, valueArr);
      end if;
                            annotation(__ModelicaAssociation_Impure=true);
    end setRealRange;

    function getReal
      "gets the indexed value of the array. The input timeIn and this strange if-else-clause is just to force the compiler to treat this call as a dynamic call. Any ideas how to fix it?"
      input ExternalMemoryLib.ExternalMemoryReal arr;
      input Integer idx;
      input Real timeIn;
      output Real val;
    algorithm
      if timeIn>0 then
        val := ExternalMemoryLib.ExternalMemory_.getRealValueAt(arr, idx-1);
      else
        val := ExternalMemoryLib.ExternalMemory_.getRealValueAt(arr, idx-1);
      end if;
                            annotation(__ModelicaAssociation_Impure=true);
    end getReal;

    function getRealRange
      input ExternalMemoryLib.ExternalMemoryReal arr;
      input Integer idx;
      input Integer size;
      input Real timeIn;
      output Real[size] val;
    algorithm
      if timeIn>0 then
        val := ExternalMemoryLib.ExternalMemory_.getRealRangeAt(arr, idx-1, size);
      else
        val := ExternalMemoryLib.ExternalMemory_.getRealRangeAt(arr, idx-1, size);
      end if;
                            annotation(__ModelicaAssociation_Impure=true);
    end getRealRange;
  end Functions;

  package Examples
    extends Modelica.Icons.ExamplesPackage;
    model Minimum
      "Try to store the global minimum of the whole x-trajectory over time"
      extends Modelica.Icons.Example;

      Real x( start=3, fixed = true);
      Real der_x( start=-1, fixed = true);
      Real y1(start=3);
      Real y2(start=3);
      ExternalMemoryReal globalMin = ExternalMemoryReal(1);
    algorithm
      //It would be so cool, if this would work, but it doesn't
      y1 := min(y1,x);
      //Thats why, we have to do it like this:
      y2 := min(ExternalMemoryLib.Functions.getReal(globalMin,0,time),x);
      ExternalMemoryLib.Functions.setReal(globalMin,0,y2,time);
    equation
      der(x) = der_x;
      der(der_x) = - x +1.0 - 0.1*time;
    end Minimum;

    model Wreckingball "destroy the wall"
      extends Modelica.Icons.Example;

      inner Modelica.Mechanics.MultiBody.World world
        annotation (Placement(transformation(extent={{-140,0},{-120,20}})));

      /*
  box stuff
  */

      parameter Integer numBoxes = 20;
      parameter Modelica.SIunits.Length boxLength = 0.1;
      parameter Modelica.SIunits.Length boxWidth = 0.1;
      parameter Modelica.SIunits.Height startWallHeight = 1.5;

      ExternalMemoryLib.ExternalMemoryReal heightArr = ExternalMemoryLib.ExternalMemoryReal(numBoxes);

      Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape[numBoxes] wall(
        each length=boxLength,
        each width=boxWidth,
        each color={255,0,0},
        height=wallHeight,
        r=boxPos,
        each lengthDirection={0,0,1},
        each widthDirection={1,0,0})
        annotation (Placement(transformation(extent={{-60,-20},{-40,0}})));

      Modelica.SIunits.Position[numBoxes,3] boxPos;
      Modelica.SIunits.Height[numBoxes] wallHeight( each start=startWallHeight);

      /*
  crane stuff
  */

      parameter Modelica.SIunits.Length rodLength = 1;

      Modelica.Mechanics.MultiBody.Parts.BodyShape mass1(
        m=1,
        r_CM={0,0,0},
        r={0,0,0}) annotation (Placement(transformation(extent={{60,40},{80,60}})));
      Modelica.Mechanics.MultiBody.Joints.Prismatic sidefeed(
        useAxisFlange=true,
        v(fixed=true, start=0),
        s(fixed=false, start=0))
        annotation (Placement(transformation(extent={{22,40},{42,60}})));
      Modelica.Mechanics.Translational.Sources.Position position(useSupport=true)
        annotation (Placement(transformation(extent={{34,68},{54,88}})));
      Modelica.Blocks.Sources.Sine sine(            amplitude=0.6, freqHz=0.5)
        annotation (Placement(transformation(extent={{4,68},{24,88}})));
      Modelica.Mechanics.MultiBody.Joints.Revolute revolute(cylinderLength=0.2,
        phi(fixed=true, start=0),
        w(fixed=true, start=0))
        annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={84,26})));
      Modelica.Mechanics.MultiBody.Parts.FixedTranslation rod(r={0,-rodLength,0})
        annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={84,-10})));
      Modelica.Mechanics.MultiBody.Parts.Body pendulum(m=500, r_CM={0,0,0})
        annotation (Placement(transformation(
            extent={{-10,-11},{10,11}},
            rotation=270,
            origin={84,-39})));
      Modelica.Mechanics.MultiBody.Joints.Prismatic forwardfeed(
        useAxisFlange=true,
        s(fixed=false, start=0),
        n={0,0,1},
        v(fixed=false, start=0))
        annotation (Placement(transformation(extent={{-32,40},{-12,60}})));


      Integer wallIdx(start=0);

      Modelica.Blocks.Sources.Trapezoid trapezoid(
        amplitude=numBoxes*boxLength,
        period=10,
        rising=4,
        falling=4,
        width=0.5)
        annotation (Placement(transformation(extent={{-70,68},{-50,88}})));
      Modelica.Mechanics.Translational.Sources.Position position1(
                                                                 useSupport=true)
        annotation (Placement(transformation(extent={{-38,68},{-18,88}})));
      Modelica.Mechanics.MultiBody.Joints.Prismatic downfeed(
        useAxisFlange=true,
        n={0,1,0},
        s(fixed=false),
        v(fixed=false))
        annotation (Placement(transformation(extent={{-102,40},{-82,60}})));
      Modelica.Mechanics.Translational.Sources.Position position2(
                                                                 useSupport=true)
        annotation (Placement(transformation(extent={{-106,66},{-86,86}})));
      Modelica.Blocks.Sources.Ramp ramp(
        height=-startWallHeight + (rodLength/2),
        duration=30,
        offset=startWallHeight + (rodLength/2))
        annotation (Placement(transformation(extent={{-138,66},{-118,86}})));
    initial algorithm
      for i in 1:numBoxes loop
        ExternalMemoryLib.Functions.setReal(heightArr,i,startWallHeight,time);
      end for;

    algorithm
      for i in 1:numBoxes loop
        wallHeight[i] := ExternalMemoryLib.Functions.getReal(heightArr, i,time);
      end for;
    equation
      for i in 1:numBoxes loop
        boxPos[i,:] = {0,wallHeight[i]*0.5,(i)*boxLength};
      end for;

      if (abs(pendulum.r_0[1]) < boxWidth) then
        wallIdx = integer(floor(pendulum.r_0[3]/boxLength));
        ExternalMemoryLib.Functions.setReal(heightArr,wallIdx,min(abs(pendulum.r_0[2]),ExternalMemoryLib.Functions.getReal(heightArr,wallIdx,time)),time);

      else
        wallIdx = 0;
      end if;

      connect(mass1.frame_a, sidefeed.frame_b) annotation (Line(
          points={{60,50},{42,50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(sidefeed.support, position.support) annotation (Line(
          points={{28,56},{28,68},{44,68}},
          color={0,127,0},
          smooth=Smooth.None));
      connect(position.flange, sidefeed.axis) annotation (Line(
          points={{54,78},{54,56},{40,56}},
          color={0,127,0},
          smooth=Smooth.None));
      connect(position.s_ref, sine.y) annotation (Line(
          points={{32,78},{25,78}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(mass1.frame_b, revolute.frame_a) annotation (Line(
          points={{80,50},{84,50},{84,36}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revolute.frame_b, rod.frame_a) annotation (Line(
          points={{84,16},{84,0}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(rod.frame_b, pendulum.frame_a) annotation (Line(
          points={{84,-20},{84,-29}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(forwardfeed.frame_b, sidefeed.frame_a) annotation (Line(
          points={{-12,50},{22,50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(position1.s_ref, trapezoid.y) annotation (Line(
          points={{-40,78},{-49,78}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(position1.flange, forwardfeed.axis) annotation (Line(
          points={{-18,78},{-14,78},{-14,56}},
          color={0,127,0},
          smooth=Smooth.None));
      connect(position1.support, forwardfeed.support) annotation (Line(
          points={{-28,68},{-28,56},{-26,56}},
          color={0,0,0},
          pattern=LinePattern.None,
          smooth=Smooth.None));
      connect(downfeed.frame_b, forwardfeed.frame_a) annotation (Line(
          points={{-82,50},{-32,50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(downfeed.frame_a, world.frame_b) annotation (Line(
          points={{-102,50},{-114,50},{-114,50},{-118,50},{-118,10},{-120,10}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(position2.support, downfeed.support) annotation (Line(
          points={{-96,66},{-96,56}},
          color={0,0,0},
          pattern=LinePattern.None,
          smooth=Smooth.None));
      connect(position2.flange, downfeed.axis) annotation (Line(
          points={{-86,76},{-84,76},{-84,56},{-84,56}},
          color={0,127,0},
          smooth=Smooth.None));
      connect(ramp.y, position2.s_ref) annotation (Line(
          points={{-117,76},{-108,76}},
          color={0,0,127},
          smooth=Smooth.None));
      annotation (                                 Diagram(coordinateSystem(
              preserveAspectRatio=false, extent={{-140,-100},{100,100}}), graphics),StopTime=20,
        Icon(coordinateSystem(extent={{-140,-100},{100,100}})));
    end Wreckingball;

    model RealArray "Just a simple testmodel."
      import ExternalMemoryLib.ExternalMemoryReal;
      parameter Integer arraySize = 3;
      ExternalMemoryReal realArray = ExternalMemoryReal(arraySize);

      Real val(start=0);
      Real v1(start=0),v2,v3;
    equation
      val = time;
      ExternalMemoryLib.Functions.setReal(realArray,1,val-1,time);
      ExternalMemoryLib.Functions.setReal(realArray,2,val+1,time);
      ExternalMemoryLib.Functions.setReal(realArray,3,val,time);

      v1 = ExternalMemoryLib.Functions.getReal(realArray,1,time);
      v2 = ExternalMemoryLib.Functions.getReal(realArray,2,time);
      v3 = ExternalMemoryLib.Functions.getReal(realArray,3,time);

    end RealArray;

    model RealArrayRange "Just a simple testmodel."
      import ExternalMemoryLib.ExternalMemoryReal;
      parameter Integer arraySize = 3;
      ExternalMemoryReal realArray = ExternalMemoryReal(arraySize);

      Real[arraySize] val;
      Real[arraySize] v1;

    equation
      val = {time+1,time,time-1};
      ExternalMemoryLib.Functions.setRealRange(realArray,1,arraySize,val,time);
      v1 = ExternalMemoryLib.Functions.getRealRange(realArray,1,arraySize,time);
    end RealArrayRange;

    model BoolArray "Just a simple testmodel."
      import ExternalMemoryLib.ExternalMemoryReal;
      parameter Integer arraySize = 3;
      ExternalMemoryBool boolArray = ExternalMemoryBool(arraySize);

      Boolean val(start=true);
      Boolean[3] v1;
    equation
      if (sin(time)>0.5) then
        val = true;
      else
        val = false;
      end if;

      when sample(0,0.1) then
        ExternalMemoryLib.ExternalMemory_.setBoolValueAt(boolArray,0, not val);
        ExternalMemoryLib.ExternalMemory_.setBoolValueAt(boolArray,1,val);
        ExternalMemoryLib.ExternalMemory_.setBoolValueAt(boolArray,2,false);
      end when;

      when sample(0,0.1) then
        v1[1] = ExternalMemoryLib.ExternalMemory_.getBoolValueAt(boolArray,0);
        v1[2] = ExternalMemoryLib.ExternalMemory_.getBoolValueAt(boolArray,1);
        v1[3] = ExternalMemoryLib.ExternalMemory_.getBoolValueAt(boolArray,2);
      end when;
    end BoolArray;

    model BoolArrayRange_notWorking "Just a simple testmodel."
      import ExternalMemoryLib.ExternalMemoryBool;
      parameter Integer arraySize = 3;
      ExternalMemoryBool boolArray = ExternalMemoryBool(arraySize);

      Boolean val(start=true);
      Boolean[3] v1;
    equation
      if (sin(time)>0.5) then
        val = true;
      else
        val = false;
      end if;

      when sample(0,0.1) then
        ExternalMemoryLib.ExternalMemory_.setBoolValueAt(boolArray,0, not val);
        ExternalMemoryLib.ExternalMemory_.setBoolValueAt(boolArray,1,val);
        ExternalMemoryLib.ExternalMemory_.setBoolValueAt(boolArray,2,false);
        v1[1:3] = ExternalMemoryLib.ExternalMemory_.getBoolRangeAt_notWorking(boolArray,0,3);
      end when;

    end BoolArrayRange_notWorking;

    model IntArray "Just a simple testmodel."
      import ExternalMemoryLib.ExternalMemoryInt;
      parameter Integer arraySize = 3;
      ExternalMemoryInt intArray = ExternalMemoryInt(arraySize);

      Integer val(start=0);
      Integer[3] v1;
    equation
      if (sin(time)>0.5) then
        val = integer(time);
      else
        val = integer(time);
      end if;

      when sample(0,0.1) then
        ExternalMemoryLib.ExternalMemory_.setIntValueAt(intArray,0, val+1);
        ExternalMemoryLib.ExternalMemory_.setIntValueAt(intArray,1,val-1);
        ExternalMemoryLib.ExternalMemory_.setIntValueAt(intArray,2,val);
      end when;

      when sample(0,0.1) then
        v1[1] = ExternalMemoryLib.ExternalMemory_.getIntValueAt(intArray,0);
        v1[2] = ExternalMemoryLib.ExternalMemory_.getIntValueAt(intArray,1);
        v1[3] = ExternalMemoryLib.ExternalMemory_.getIntValueAt(intArray,2);
      end when;
    end IntArray;

    model IntArrayRange "Just a simple testmodel."
      import ExternalMemoryLib.ExternalMemoryInt;
      parameter Integer arraySize = 3;
      ExternalMemoryInt intArray = ExternalMemoryInt(arraySize);

      Integer val(start=0);
      Integer[3] v1;
    equation
      if (sin(time)>0.5) then
        val = integer(time);
      else
        val = integer(time);
      end if;

      when sample(0,0.1) then
        ExternalMemoryLib.ExternalMemory_.setIntValueAt(intArray,0, val+1);
        ExternalMemoryLib.ExternalMemory_.setIntValueAt(intArray,1,val-1);
        ExternalMemoryLib.ExternalMemory_.setIntValueAt(intArray,2,val);
      end when;

      when sample(0,0.1) then
        v1 = ExternalMemoryLib.ExternalMemory_.getIntRangeAt(intArray,0,arraySize);
      end when;
    end IntArrayRange;

    model RealArray_withTimeControl "Just a simple testmodel."
      import ExternalMemoryLib.ExternalMemoryReal;
      parameter Integer arraySize = 3;
      ExternalMemoryRealTC realArray = ExternalMemoryRealTC(arraySize,time);

      Real val(start=0);
      Real v1(start=0),v2,v3;
    equation
      val = time;
      when sample(0,0.1) then
        ExternalMemoryLib.ExternalMemory_.setRealValueAtWithTC(realArray,0,val-1, time);
        ExternalMemoryLib.ExternalMemory_.setRealValueAtWithTC(realArray,1,val+1, time);
        ExternalMemoryLib.ExternalMemory_.setRealValueAtWithTC(realArray,2,val, time);
      end when;

        v1 = ExternalMemoryLib.ExternalMemory_.getRealValueAtWithTC(realArray,0,time,8);
        v2 = ExternalMemoryLib.ExternalMemory_.getRealValueAtWithTC(realArray,1,time,8);
        v3 = ExternalMemoryLib.ExternalMemory_.getRealValueAtWithTC(realArray,2,time,8);
    end RealArray_withTimeControl;

    model RealArray_noWrapper "Just a simple testmodel."
      import ExternalMemoryLib.ExternalMemoryReal;
      parameter Integer arraySize = 3;
      ExternalMemoryReal realArray = ExternalMemoryReal(arraySize);

      Real val(start=0);
      Real v1(start=0),v2,v3;
    algorithm
      val :=time;
      ExternalMemoryLib.ExternalMemory_.setRealValueAt(realArray,1-1,val-1);
      ExternalMemoryLib.ExternalMemory_.setRealValueAt(realArray,2-1,val+1);
      ExternalMemoryLib.ExternalMemory_.setRealValueAt(realArray,3-1,val);

      v1 :=ExternalMemoryLib.ExternalMemory_.getRealValueAt(realArray, 1 - 1);
      v2 :=ExternalMemoryLib.ExternalMemory_.getRealValueAt(realArray, 2 - 1);
      v3 :=ExternalMemoryLib.ExternalMemory_.getRealValueAt(realArray, 3 - 1);

    end RealArray_noWrapper;
  end Examples;

  class ExternalMemoryReal " An object for external memory"
    extends ExternalObject;
    function constructor
      "Creates an instance of an external array of type double."
      input Integer size = 1 "size of the array";
      output ExternalMemoryReal extMem;
      external "C" extMem =  externalMemoryRealConstructor(size)
        annotation(Include = "#include \"ExternalMemory.h\"",
                   Library = "ExternalMemory",
                   __iti_dll = "ITI_ExternalMemory.dll",
                   __iti_dllNoExport = false);
    end constructor;

    function destructor
      input ExternalMemoryReal extMem;
      external "C" externalMemoryRealDestructor(extMem)
        annotation(Include = "#include \"ExternalMemory.h\"",
                   Library = "ExternalMemory",
                   __iti_dll = "ITI_ExternalMemory.dll",
                   __iti_dllNoExport = false);
    end destructor;
  end ExternalMemoryReal;

  class ExternalMemoryInt " An object for external memory"
    extends ExternalObject;
    function constructor
      "Creates an instance of an external array of type double."
      input Integer size = 1 "size of the array";
      output ExternalMemoryInt extMem;
      external "C" extMem =  externalMemoryIntConstructor(size)
        annotation(Include = "#include \"ExternalMemory.h\"",
                   Library = "ExternalMemory",
                   __iti_dll = "ITI_ExternalMemory.dll",
                   __iti_dllNoExport = false);
    end constructor;

    function destructor
      input ExternalMemoryInt extMem;
      external "C" externalMemoryIntDestructor(extMem)
        annotation(Include = "#include \"ExternalMemory.h\"",
                   Library = "ExternalMemory",
                   __iti_dll = "ITI_ExternalMemory.dll",
                   __iti_dllNoExport = false);
    end destructor;
  end ExternalMemoryInt;

  class ExternalMemoryBool " An object for external memory"
    extends ExternalObject;
    function constructor
      "Creates an instance of an external array of type double."
      input Integer size = 1 "size of the array";
      output ExternalMemoryBool extMem;
      external "C" extMem =  externalMemoryBoolConstructor(size)
        annotation(Include = "#include \"ExternalMemory.h\"",
                   Library = "ExternalMemory",
                   __iti_dll = "ITI_ExternalMemory.dll",
                   __iti_dllNoExport = false);
    end constructor;

    function destructor
      input ExternalMemoryBool extMem;
      external "C" externalMemoryBoolDestructor(extMem)
        annotation(Include = "#include \"ExternalMemory.h\"",
                   Library = "ExternalMemory",
                   __iti_dll = "ITI_ExternalMemory.dll",
                   __iti_dllNoExport = false);
    end destructor;
  end ExternalMemoryBool;

  class ExternalMemoryRealTC " An object for external memory with time control"
    extends ExternalObject;
    function constructor
      "Creates an instance of an external array of type double."
      input Integer size = 1 "size of the array";
      input Real timeIn = 2 "time of the first value";
      output ExternalMemoryRealTC extMem;
      external "C" extMem =  externalMemoryRealTCConstructor(size,timeIn)
        annotation(Include = "#include \"ExternalMemory.h\"",
                   Library = "ExternalMemory",
                   __iti_dll = "ITI_ExternalMemory.dll",
                   __iti_dllNoExport = false);
    end constructor;

    function destructor
      input ExternalMemoryRealTC extMem;
      external "C" externalMemoryRealTCDestructor(extMem)
        annotation(Include = "#include \"ExternalMemory.h\"",
                   Library = "ExternalMemory",
                   __iti_dll = "ITI_ExternalMemory.dll",
                   __iti_dllNoExport = false);
    end destructor;
  end ExternalMemoryRealTC;

  package ExternalMemory_
    function setRealValueAt
      input ExternalMemoryReal extMem;
      input Integer idx "0-based";
      input Real value;
      external "C" setRealValueAt(extMem, idx, value)
        annotation(Include = "#include \"ExternalMemory.h\"",
                   Library = "ExternalMemory",
                   __iti_dll = "ITI_ExternalMemory.dll",
                   __iti_dllNoExport = false);
                   annotation(__ModelicaAssociation_Impure=true);
    end setRealValueAt;

    function getRealValueAt
      input ExternalMemoryReal extMem;
      input Integer idx "0-based";
      output Real value;
      external "C" getRealValueAt(extMem, idx, value)
        annotation(Include = "#include \"ExternalMemory.h\"",
                   Library = "ExternalMemory",
                   __iti_dll = "ITI_ExternalMemory.dll",
                   __iti_dllNoExport = false);
                   annotation(__ModelicaAssociation_Impure=true);
    end getRealValueAt;

    function getRealRangeAt
      input ExternalMemoryReal extMem;
      input Integer startIdx "0-based";
      input Integer len "length of range";
      output Real[len] value;
      external "C" getRealRangeAt(extMem, startIdx, len, value)
        annotation(Include = "#include \"ExternalMemory.h\"",
                   Library = "ExternalMemory",
                   __iti_dll = "ITI_ExternalMemory.dll",
                   __iti_dllNoExport = false);
                                             annotation(__ModelicaAssociation_Impure=true);
    end getRealRangeAt;

      function setRealRangeAt
      input ExternalMemoryReal extMem;
      input Integer startIdx "0-based";
      input Integer len "length of range";
      input Real[len] valArray;
      external "C" setRealRangeAt(extMem, startIdx, len, valArray)
        annotation(Include = "#include \"ExternalMemory.h\"",
                   Library = "ExternalMemory",
                   IncludeDirectory = "modelica://ExternalMemoryLib/Resources/Include",
                   LibraryDirectory = "modelica://ExternalMemoryLib/Resources/Library/win32",
                   __iti_dll = "ITI_ExternalMemory.dll",
                   __iti_dllNoExport = false);
                                              annotation(__ModelicaAssociation_Impure=true);
      end setRealRangeAt;

    function setIntValueAt
      input ExternalMemoryInt extMem;
      input Integer idx "0-based";
      input Integer value;
      external "C" setIntValueAt(extMem, idx, value)
        annotation(Include = "#include \"ExternalMemory.h\"",
                   Library = "ExternalMemory",
                   __iti_dll = "ITI_ExternalMemory.dll",
                   __iti_dllNoExport = false);
                                              annotation(__ModelicaAssociation_Impure=true);
    end setIntValueAt;

    function getIntValueAt
      input ExternalMemoryInt extMem;
      input Integer idx "0-based";
      output Integer value;
      external "C" getIntValueAt(extMem, idx, value)
        annotation(Include = "#include \"ExternalMemory.h\"",
                   Library = "ExternalMemory",
                   __iti_dll = "ITI_ExternalMemory.dll",
                   __iti_dllNoExport = false);
                                              annotation(__ModelicaAssociation_Impure=true);
    end getIntValueAt;

    function getIntRangeAt
      input ExternalMemoryInt extMem;
      input Integer startIdx "0-based";
      input Integer len "length of range";
      output Integer[len] value;
      external "C" getIntRangeAt(extMem, startIdx, len, value)
        annotation(Include = "#include \"ExternalMemory.h\"",
                   Library = "ExternalMemory",
                   __iti_dll = "ITI_ExternalMemory.dll",
                   __iti_dllNoExport = false);
                                              annotation(__ModelicaAssociation_Impure=true);
    end getIntRangeAt;

    function setBoolValueAt
      input ExternalMemoryBool extMem;
      input Integer idx "0-based";
      input Boolean value;
      external "C" setBoolValueAt(extMem, idx, value)
        annotation(Include = "#include \"ExternalMemory.h\"",
                   Library = "ExternalMemory",
                   __iti_dll = "ITI_ExternalMemory.dll",
                   __iti_dllNoExport = false);
                                              annotation(__ModelicaAssociation_Impure=true);
    end setBoolValueAt;

    function getBoolValueAt
      input ExternalMemoryBool extMem;
      input Integer idx "0-based";
      output Boolean value;
      external "C" getBoolValueAt(extMem, idx, value)
        annotation(Include = "#include \"ExternalMemory.h\"",
                   Library = "ExternalMemory",
                   __iti_dll = "ITI_ExternalMemory.dll",
                   __iti_dllNoExport = false);
                                              annotation(__ModelicaAssociation_Impure=true);
    end getBoolValueAt;

    function getBoolRangeAt_notWorking
      "For any reason, this function is not working wiht dymola properly."
      input ExternalMemoryBool extMem;
      input Integer startIdx "0-based";
      input Integer len "length of range";
      output Boolean[len] value;
      external "C" getBoolRangeAt(extMem, startIdx, len, value)
        annotation(Include = "#include \"ExternalMemory.h\"",
                   Library = "ExternalMemory",
                   __iti_dll = "ITI_ExternalMemory.dll",
                   __iti_dllNoExport = false);
                                              annotation(__ModelicaAssociation_Impure=true);
    end getBoolRangeAt_notWorking;

    function setRealValueAtWithTC
      input ExternalMemoryRealTC extMem;
      input Integer idx "0-based";
      input Real value;
      input Real timeIn;
      external "C" setRealValueAtWithTC(extMem, idx, value, timeIn)
        annotation(Include = "#include \"ExternalMemory.h\"",
                   Library = "ExternalMemory",
                   __iti_dll = "ITI_ExternalMemory.dll",
                   __iti_dllNoExport = false);
                                              annotation(__ModelicaAssociation_Impure=true);
    end setRealValueAtWithTC;

    function getRealValueAtWithTC
      input ExternalMemoryRealTC extMem;
      input Integer idx "0-based";
      input Real timeIn;
      input Real fallbackValue;
      output Real value;
      external "C" getRealValueAtWithTC(extMem, idx, value, timeIn, fallbackValue)
        annotation(Include = "#include \"ExternalMemory.h\"",
                   Library = "ExternalMemory",
                   __iti_dll = "ITI_ExternalMemory.dll",
                   __iti_dllNoExport = false);
                                              annotation(__ModelicaAssociation_Impure=true);
    end getRealValueAtWithTC;

    function getRealRangeAtWithTC
      input ExternalMemoryReal extMem;
      input Integer startIdx "0-based";
      input Integer len "length of range";
      input Real timeIn;
      input Real[len] fallbackValue;
      output Real[len] value;
      external "C" getRealRangeAtWithTC(extMem, startIdx, len, value, timeIn, fallbackValue)
        annotation(Include = "#include \"ExternalMemory.h\"",
                   Library = "ExternalMemory",
                   __iti_dll = "ITI_ExternalMemory.dll",
                   __iti_dllNoExport = false);
                                              annotation(__ModelicaAssociation_Impure=true);
    end getRealRangeAtWithTC;

  end ExternalMemory_;

  annotation (uses(Modelica(version="3.2.1")));
end ExternalMemoryLib;
