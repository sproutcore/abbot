/**
	@overview Remove JsDoc comments from source code and save file.
	@author Michael Mathews micmath@gmail.com
*/

function deploy_begin(context) {
	context.src = context.d+"/src";
	MakeDir(context.src);
}

function deploy_each(sourceFile, context) {
	var name = sourceFile.fileName.replace(/(\.\.?)?[\/\\]/g, "_");
	inform("Saving stripped source file to "+name);
	
	var stripped = sourceFile.content.replace(/\/\*\*[\S\s]+?\*\//g, "");
	SaveFile(context.src, name, stripped);
}

function deploy_finish(context) {	
}
