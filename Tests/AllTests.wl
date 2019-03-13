#!/usr/bin/env wolframscript

Print["Mathematica Version: ", $Version];

<< SpinWeightedSpheroidalHarmonics`
<< Teukolsky`

testFiles = FileNames["*.wlt", 
  FileNameJoin[{$TeukolskyInstallationDirectory, "Tests"}]];

reports = TestReport /@ testFiles;

numTestsSucceeded = Total[#["TestsSucceededCount"] & /@ reports];
numTestsFailed    = Total[#["TestsFailedCount"]& /@ reports];
numTests          = testsSucceededCount + failureCount;

time = QuantityMagnitude[Total[(#["TimeElapsed"] & /@ reports)], "Seconds"];

(* Generate XML for a single test result *)
testResultXML[result_] :=
  XMLElement["testcase",
    {"name" -> ToString[result["TestID"]], 
     "time" -> ToString[QuantityMagnitude[result["AbsoluteTimeUsed"], "Seconds"]]}, 
    Switch[result["Outcome"],
      "Failure",
        {XMLElement["failure", {}, {XMLObject["CDATASection"][
          "Input: " <> ToString[result["Input"], InputForm] <> "\n" <>
          "Expected output: " <> ToString[result["ExpectedOutput"], InputForm] <> "\n" <>
          "Actual output: " <> ToString[result["ActualOutput"], InputForm]]}]},
      "MessagesFailure",
        {XMLElement["failure", {}, {XMLObject["CDATASection"][
          "Expected Messages: " <> ToString[result["ExpectedMessages"], InputForm] <> "\n" <>
          "Actual Messages: " <> ToString[result["ActualMessages"], InputForm]]}]},
      "Error",
          {XMLElement["failure", {}, {XMLObject["CDATASection"]["Error"]}]},
      "Success",
          {}
    ]
];

testsuiteXML[report_] :=
  XMLElement["testsuite",
    {"name" -> report["Title"],
     "tests" -> ToString[report["TestsSucceededCount"] + report["TestsFailedCount"]],
     "failures" -> ToString[report["TestsFailedCount"]],
     "time" -> ToString[QuantityMagnitude[report["TimeElapsed"], "Seconds"]]},
    Map[testResultXML, Values[report["TestResults"]]]];

xml = XMLObject["Document"][{XMLObject["Declaration"]["Version" -> "1.0",  "Encoding" -> "UTF-8"]}, 
  XMLElement[
    "testsuites",
    {"name" -> "Teukolsky Tests", 
     "time" -> ToString[time],
     "tests" -> ToString[numTests], 
     "failures" -> ToString[numTestsFailed]}, 
     testsuiteXML /@ reports
     ], {}];

Export["TestReport.xml", xml, "XML"]