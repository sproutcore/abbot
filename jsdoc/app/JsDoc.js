/**
 * @fileOverview
 * @name JsDoc Toolkit
 * @author Michael Mathews micmath@gmail.com
 * @url $HeadURL: https://jsdoc-toolkit.googlecode.com/svn/tags/jsdoc_toolkit-1.4.0b/app/JsDoc.js $
 * @revision $Id: JsDoc.js 327 2007-11-13 00:18:23Z micmath $
 * @license <a href="http://en.wikipedia.org/wiki/MIT_License">X11/MIT License</a>
 *          (See the accompanying README file for full details.)
 */

/** @class Handle reporting messages to the user.
	@static
*/
LOG = {
	warn: function(msg, e) {
		if (e) msg = e.fileName+", line "+e.lineNumber+": "+msg;
		
		msg = ">> WARNING: "+msg;
		LOG.warnings.push(msg);
		if (LOG.out) LOG.out.write(msg+"\n");
		else print(msg);
	},

	inform: function(msg) {
		msg = " > "+msg;
		if (LOG.out) LOG.out.write(msg+"\n");
		else if (typeof VERBOSE != "undefined" && VERBOSE) print(msg);
	}
};
LOG.warnings = [];

/**
	@class An automated documentation publishing system for JavaScript.
	@static
	@author Michael Mathews <a href="mailto:micmath@gmail.com">micmath@gmail.com</a>
*/
JsDoc = {
	/** The version number of this release. */
	VERSION: "1.4.0b",
	
	/**
	 * Print out the expected usage syntax for this script on the command
	 * line. This is called automatically by using the -h/--help option.
	 */
	usage: function() {
		print("USAGE: java -jar app/js.jar app/jsdoc.js [OPTIONS] <SRC_DIR> <SRC_FILE> ...");
		print("");
		print("OPTIONS:");
		print("  -t=<PATH> or --template=<PATH>\n          Required. Use this template to format the output.\n");
		print("  -d=<PATH> or --directory=<PATH>\n          Output to this directory (defaults to js_docs_out).\n");
		print("  -e=<ENCODING> or --encoding=<ENCODING>\n          Use this encoding to read and write files.\n");
		
		print("  -r=<DEPTH> or --recurse=<DEPTH>\n          Descend into src directories.\n");
		print("  -x=<EXT>[,EXT]... or --ext=<EXT>[,EXT]...\n          Scan source files with the given extension/s (defaults to js).\n");
		print("  -a or --allfunctions\n          Include all functions, even undocumented ones.\n");
		print("  -A or --Allfunctions\n          Include all functions, even undocumented, underscored ones.\n");
		print("  -p or --private\n          Include symbols tagged as private.\n");
		print("  -o=<PATH> or --out=<PATH>\n          Print log messages to a file (defaults to stdout).\n");
		print("  -h or --help\n          Show this message and exit.\n");
		
		java.lang.System.exit(0);
	},
	
	/**
	 * @param {string[]} srcFiles Paths to files to be documented
	 * @return {DocFile[]}
	 */
	parse: function(srcFiles) {
		var files = [];
		
		if (typeof srcFiles == "string") srcFiles = [srcFiles];	
		var parser = new JsParse();
		
		srcFiles = srcFiles.sort();
		
		var docs = new DocFileGroup();
		
		// handle setting up relationships between symbols here
		for (var f = 0; f < srcFiles.length; f++) {
			var srcFile = srcFiles[f];
			
			LOG.inform("Tokenizing: file "+(f+1)+", "+srcFile);
			var src = IO.readFile(srcFile);
			
			var tokens = new TokenReader(src).tokenize();
			LOG.inform("\t"+tokens.length+" tokens found.");
			var ts = new TokenStream(tokens);
			
			var file = new DocFile(srcFile);
			parser.parse(ts);
			LOG.inform("\t"+parser.symbols.length+" symbols found.");
			
			file.addSymbols(parser.symbols, JsDoc.opt);
			if (parser.overview) file.overview = parser.overview;
			
			docs.addDocFile(file);
		}
		return docs;
	}
};

/** Override this dummy function in your template. */
function publish() {}