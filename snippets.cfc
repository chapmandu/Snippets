component output="false" {

  // TODO: mixin arg..
	// TODO: wheels version (2.x)

	include "/wheels/public/docs/functions.cfm";
	include "/wheels/view/sanitize.cfm";
	include "/wheels/global/internal.cfm";
	include "/wheels/global/util.cfm";

  public any function init() {
    this.version = "2.x";
    return this;
  }

  /**
   * This plugin version number
   */
  public string function pluginVersion() {
    return "0.1.0";
  }

	public any function gimme(required string editor) {
		switch(arguments.editor) {
			case "sublime":
				createSublimeSnippets();
				break;
			case "vscode":
				createVSCodeSnippets();
				break;
			case "atom":
				createAtomSnippets();
				break;
		}
	}

	/**
	 * Returns an array of structs describing the editors avaiable for snippet generation
	 */
  public array function getEditors() {
		return [
			{value="atom", text="Atom"},
			{value="sublime", text="Sublime Text"},
			{value="vscode", text="Visual Studio Code"}
		]
	}


	public boolean function createVSCodeSnippets(array funcs=_getFunctions()) {

		local.path = ExpandPath("/app/plugins/snippets/lang.cfml.json");
		local.struct = StructNew("linked");
		for (local.func in arguments.funcs) {
			local.struct[func.name] = {
				"prefix"=func.name,
				"description"=stripTags(Trim(func.hint)),
				"body"=["#func.name#(#_buildArguments(func=local.func, includeOptional=false, editor="vscode")#)"]
			};
			local.struct[func.name & "-long"] = {
				"prefix"=func.name & " long",
				"description"=stripTags(Trim(func.hint)),
				"body"=["#func.name#(#_buildArguments(func=local.func, includeOptional=true, editor="vscode")#)"]
			};
		}

		local.content = SerializeJSON(local.struct);
		FileWrite(local.path, local.content);
		header name="Content-disposition" value="inline; filename=#GetFileFromPath(local.path)#" {};
		content file="#local.path#" type="application/unknown" deletefile="true" {};

		return true;
	}

	public boolean function createSublimeSnippets(array funcs=_getFunctions()) {

		local.lf = Chr(10);
		local.zipFilePath = ExpandPath("/app/plugins/snippets/sublime-snippets.zip");
		local.zippableDirectoryPath = ExpandPath("/app/plugins/snippets/sublime") & "/";
		if (DirectoryExists(local.zippableDirectoryPath)) {
			DirectoryDelete(local.zippableDirectoryPath, true);
		}
		DirectoryCreate(local.zippableDirectoryPath);

		for (local.func in arguments.funcs) {
			local.content = '<snippet>' & local.lf;
			local.content &= '  <content><![CDATA[#func.name#(#_buildArguments(func=local.func, includeOptional=false, editor="sublime")#)]]></content>' & local.lf;
			local.content &= '  <tabTrigger>#func.name#</tabTrigger>' & local.lf;
			local.content &= '  <!-- <scope>source.cfml</scope> -->' & local.lf;
			local.content &= '  <description>#XmlFormat(stripTags(Trim(func.hint)))#</description>' & local.lf;
			local.content &= '</snippet>';
			local.snippetFilePath = local.zippableDirectoryPath & "wheels-" & func.name & ".sublime-snippet";

			FileWrite(local.snippetFilePath, local.content);

			local.content = '<snippet>' & local.lf;
			local.content &= '  <content><![CDATA[#func.name#(#_buildArguments(func=local.func, includeOptional=true, editor="sublime")#)]]></content>' & local.lf;
			local.content &= '  <tabTrigger>#func.name# long</tabTrigger>' & local.lf;
			local.content &= '  <!-- <scope>source.cfml</scope> -->' & local.lf;
			local.content &= '  <description>#XmlFormat(stripTags(Trim(func.hint)))#</description>' & local.lf;
			local.content &= '</snippet>';
			local.snippetFilePath = local.zippableDirectoryPath & "wheels-" & func.name & "-long" & ".sublime-snippet";
			FileWrite(local.snippetFilePath, local.content);
		}

		zip action="zip" source="#local.zippableDirectoryPath#" file="#local.zipFilePath#";

		DirectoryDelete(local.zippableDirectoryPath, true);

		header name="Content-disposition" value="inline; filename=#GetFileFromPath(local.zipFilePath)#" {};
		content file="#local.zipFilePath#" type="application/zip" deletefile="true" {};

		return true;
	}

	public boolean function createAtomSnippets(array funcs=_getFunctions()) {

		local.lf = Chr(13);
		local.path = ExpandPath("/app/plugins/snippets/snippets.cson");

		local.content = "'.text.html.cfml, .source.cfml, .source.cfscript':" & local.lf;
		for (local.func in arguments.funcs) {
			local.content &= "  '#func.name#':" & local.lf;
			local.content &= "    'prefix': '#func.name#'" & local.lf;
			local.content &= "    'body': " & '"#func.name#(#_buildArguments(func=local.func, includeOptional=false, editor="atom")#)"' & local.lf;

			// local.content &= "  '#func.name# long':" & local.lf;
			// local.content &= "    'prefix': '#func.name# long'" & local.lf;
			// local.content &= "    'body': " & '"#func.name#(#_buildArguments(func=local.func, includeOptional=true, editor="atom")#)"' & local.lf;
		}

		FileWrite(local.path, local.content);
		header name="Content-disposition" value="inline; filename=#GetFileFromPath(local.path)#" {};
		content file="#local.path#" type="application/unknown" deletefile="true" {};

		return true;
	}

	public string function _buildArguments(
		required struct func,
		required boolean includeOptional,
		required string editor
	) {

		local.rv = "";
		local.i = 0;
		for (local.arg in arguments.func.parameters) {
			if (arguments.includeOptional && !local.arg.required) {

				local.i++;
				// quote string args
				if (local.arg.type == "string") {
					local.nameAndValue = '#local.arg.name#="$#local.i#"';
				} else {
					local.nameAndValue = '#arg.name#=$#local.i#';
				}

				local.rv = ListAppend(local.rv, local.nameAndValue);
			}
		}

		local.rv = ListChangeDelims(local.rv, ", ");

		return local.rv;
	}

	public array function _getFunctions() {

		local.documentScope=[];

		arrayAppend(local.documentScope, {
				"name": "controller",
				"scope": createObject("component", "app.controllers.Controller")
		});
		arrayAppend(local.documentScope, {
				"name": "model",
				"scope": createObject("component", "app.models.Model")
		});
		arrayAppend(local.documentScope, {
				"name": "mapper",
				"scope": application.wheels.mapper
		});
		arrayAppend(local.documentScope, {
				"name": "migrator",
				"scope": application.wheels.migrator
		});

		// Array of functions to ignore
		local.ignore = ["config","init"];

		// Populate the main documentation
		return $populateDocFunctionMeta(local.documentScope, local.ignore);
	}

}
