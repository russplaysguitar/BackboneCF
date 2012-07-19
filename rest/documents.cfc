<cfcomponent rest="true" restpath="restService">     
    <cffunction name="getAll" access="remote" returntype="array" httpmethod="GET"> 
        <cfreturn [{id:100, content:'one'},{id:200, content:'two'}]> 
    </cffunction> 

    <cffunction name="get" access="remote" returntype="struct" httpmethod="GET" restPath="{id}"> 
    	<cfargument name="id" type="string" required="true" restargsource="Path">
        <cfreturn {id:300, content:'three'} > 
    </cffunction> 
</cfcomponent>