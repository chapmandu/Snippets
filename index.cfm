<cfoutput>

	<cfset _plugin = application.wheels.plugins.snippets.init()>

	<cfif StructKeyExists(params, "editor")>
		<cfset _plugin.gimme(params.editor)>
	</cfif>

  <h1>Wheels 2.x Snippets Generator</h1>
  <h3>Generates Wheels 2.x Snippets for a number of popular editors.</h3>

	<cfloop array="#_plugin.getEditors()#" index="i">
		#linkTo(text=i.text, controller="wheels", action="wheels", params="view=plugins&name=snippets&editor=#i.value#")#<br>
	</cfloop>

  <div align="center" style="font-size:0.8em;">Snippets V#_plugin.pluginVersion()#</div>
</cfoutput>
