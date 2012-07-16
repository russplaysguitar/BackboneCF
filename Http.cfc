<cfcomponent>

	<cffunction name="request" access="public" returnType="string">
		<cfargument name="url" type="string" required="true">
		<cfargument name="port" type="numeric" default="80">
		<cfargument name="type" type="string" default="GET">
		<cfargument name="contentType" type="string" default="application/json">
		<cfargument name="data" type="string" default="">	
		<cfargument name="headers" type="struct" default="#structNew()#">

		<cfhttp result="result" url="#arguments.url#" method="#arguments.type#" port="#arguments.port#">
			<cfhttpparam name="Content-Type" value="#arguments.contentType#" type="header">
			<cfif arguments.data NEQ ''>
				<cfhttpparam name="data" value="#arguments.data#" type="body">
			</cfif>
			<cfloop collection="#headers#" item="item">
				<cfhttpparam name="#item#" value="#headers[item]#" type="header">
			</cfloop>
		</cfhttp>

		<cfreturn result.fileContent>
	</cffunction>

</cfcomponent>