/**
 * @fileOverview
 * @name JsIO
 * @author Michael Mathews micmath@gmail.com
 * @url $HeadURL: https://jsdoc-toolkit.googlecode.com/svn/tags/jsdoc_toolkit-1.4.0b/app/JsIO.js $
 * @revision $Id: JsIO.js 303 2007-11-11 18:59:08Z micmath $
 * @license <a href="http://en.wikipedia.org/wiki/MIT_License">X11/MIT License</a>
 *          (See the accompanying README file for full details.)
 */

// shortcuts
FileWriter = Packages.java.io.FileWriter;
File = Packages.java.io.File;

/**
 * @class Friendly interface to Java file operations. Requires Rhino.
 * @static
 */
var IO = {
	FileSeparator: Packages.java.io.File.separator,
	
	/**
	 * Use to save content to a file.
	 * @param {string} outDir Path to directory to save into.
	 * @param {string} fileName Name to use for the new file.
	 * @param {string} content To write to the new file.
	 */
	saveFile: function(outDir, fileName, content) {
        var out = new Packages.java.io.PrintWriter(
			new Packages.java.io.OutputStreamWriter(
				new Packages.java.io.FileOutputStream(outDir+IO.FileSeparator+fileName),
				IO.encoding
			)
		);
        out.write(content);
        out.flush();
        out.close();
    },
	
	/**
	 * Gets the contents of a file.
	 * @param {path|url} url
	 * @return {string} The contents of the file at the given location.
	 */
	readFile: function(path) {
        return readFile(path, IO.encoding);
    },
	
	/**
	 * Use to copy a file from one directory to another. Can take binary files too.
	 * @param {string} inFile Path to the source file.
	 * @param {string} outDir Path to directory to save into.
	 * @param {string} fileName Name to use for the new file.
	 */
	copyFile: function(inFile, outDir, fileName) {
		if (fileName == null) fileName = Util.fileName(inFile);
	
		var inFile = new File(inFile);
		var outFile = new File(outDir+IO.FileSeparator+fileName);
		
		var bis = new Packages.java.io.BufferedInputStream(new Packages.java.io.FileInputStream(inFile), 4096);
		var bos = new Packages.java.io.BufferedOutputStream(new Packages.java.io.FileOutputStream(outFile), 4096);
		var theChar;
		while ((theChar = bis.read()) != -1) {
			bos.write(theChar);
		}
		bos.close();
		bis.close();
	},
	
	/**
	 * Use to create a new directory.
	 * @param {string} dirname Path of directory you wish to create.
	 */
	makeDir: function(dirName) {
		(new File(dirName)).mkdir();
	},
	
	/**
	 * Get recursive list of files in a directory.
	 * @param {array} dirs Paths to directories to search.
	 * @param {int} recurse How many levels to descend, defaults to 1.
	 * @return {array} Paths to found files.
	 */
	ls: function(dir, recurse, allFiles, path) {
		if (path === undefined) { // initially
			var allFiles = [];
			var path = [dir];
		}
		if (path.length == 0) return allFiles;
		if (recurse === undefined) recurse = 1;
		
		dir = new File(dir);
		if (!dir.directory) return [String(dir)];
		var files = dir.list();
		
		for (var f = 0; f < files.length; f++) {
			var file = String(files[f]);
			if (file.match(/^\.[^\.\/\\]/)) continue; // skip dot files

			if ((new File(path.join("/")+"/"+file)).list()) { // it's a directory
				path.push(file);
				if (path.length-1 < recurse) IO.ls(path.join("/"), recurse, allFiles, path);
				path.pop();
			}
			else {
				allFiles.push((path.join("/")+"/"+file).replace("//", "/"));
			}
		}

		return allFiles;
	},
	
	/**
	 * Check if a filepath exists.
	 * @author vinces1979
	 */
	exists: function(path) {
		file = new File(path);

		if (file.isDirectory()){
			return true;
		}
		if (!file.exists()){
			LOG.inform('Path not found: ' + path);
			return false;
		}
		if (!file.canRead()){
			LOG.inform('Path not readable: ' + path);
			return false;
		}
		return true;
	},
	
	/**
	 * Create an open filehandle.
	 * @param {string} path Path to file to open.
	 * @param {boolean} append Open in append mode?
	 * @return {FileWriter} A filehandle that can write(string) and close().
	 */
	open: function(path, append) {
        var append = true;
        var outFile = new Packages.java.io.File(path);
        var out = new Packages.java.io.PrintWriter(
			new Packages.java.io.OutputStreamWriter(
				new Packages.java.io.FileOutputStream(outFile, append),
				IO.encoding
			)
		);
        return out;
    },
    
    setEncoding: function(encoding) {
    	if (/ISO-8859-([0-9]+)/i.test(encoding)) {
    		IO.encoding = "ISO8859_"+RegExp.$1;
    	}
    	else {
    		IO.encoding = encoding
    	}
    }
};

IO.encoding = "utf-8";
