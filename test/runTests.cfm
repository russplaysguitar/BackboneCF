<!--- note: To run, you may need to update the "directory" and "componentPath" attributes --->

<cfinvoke component="mxunit.runner.DirectoryTestSuite"
		  componentPath="backbone.test" 
          method="run"
          directory="#expandPath('.')#"
		  recurse="false"
		  returnvariable="results" />

<cfoutput>#results.getResultsOutput('extjs')#</cfoutput>