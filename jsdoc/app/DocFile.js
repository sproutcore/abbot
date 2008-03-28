/**
 * @fileOverview
 * @name DocFile
 * @author Michael Mathews micmath@gmail.com
 * @url $HeadURL: https://jsdoc-toolkit.googlecode.com/svn/tags/jsdoc_toolkit-1.4.0b/app/DocFile.js $
 * @revision $Id: DocFile.js 260 2007-10-03 22:18:38Z micmath $
 * @license <a href="http://en.wikipedia.org/wiki/MIT_License">X11/MIT License</a>
 *          (See the accompanying README file for full details.)
 */

/**
 * @class Represents a collection of docFiles.
 * @constructor
 * @author Michael Mathews <a href="mailto:micmath@gmail.com">micmath@gmail.com</a>
 */
function DocFileGroup() {
	this.files = [];
}

/**
 * @param {DocFile} docFile Add this docFile to this group.
 */
DocFileGroup.prototype.addDocFile = function(docFile) {
	docFile.fileGroup = this;
	docFile.fileGroup.circularReference = 1; // keeps dumper from getting dizzy
	this.files.push(docFile);
}

/**
 * Search the entire dofFileGroup for a certain symbol.
 * @param {string} alias The full alias name of the symbol.
 * @return {Symbol}
 */
DocFileGroup.prototype.getSymbol = function(alias) {
	for (var f = 0; f < this.files.length; f++) {
		var symbol = this.files[f].getSymbol(alias);
		if (symbol) return symbol;
	}
}

/**
 * @class Represents a collection of doclets associated with a file.
 * @constructor
 * @author Michael Mathews <a href="mailto:micmath@gmail.com">micmath@gmail.com</a>
 * @param {string} [path] The file path to the source file.
 */
function DocFile(path) {
	this.path = path;
	this.filename = Util.fileName(this.path);
	this.overview = new Symbol(this.filename, [], "FILE", "/** @overview */");
	this.symbols = [];
	fileGroup = null;
}

/**
 * Add a group of doclets. Finds relationships between doclets within the group
 * @param {Symbol[]} symbols
 * @param {object} opt Passed in from the command line.
 */
DocFile.prototype.addSymbols = function(symbols, opt) {
	for (var s = 0; s < symbols.length; s++) {
		if (symbols[s].doc.getTag("ignore").length)
			continue;
			
		if (symbols[s].isPrivate && !opt.p)
			continue;
			
		symbols[s].file = this;
		symbols[s].file.circularReference = 1; // keeps dumper from getting dizzy
		
		var parents;
		if ((parents = symbols[s].doc.getTag("memberof")) && parents.length) {
			if (symbols[s].name.indexOf(parents[0]+".") == 0) {
				symbols[s].name = symbols[s].name.replace(parents[0]+".", parents[0]+"/");
				symbols[s].isStatic = true;
			}
			else if (symbols[s].name.indexOf(parents[0]+"/") != 0) {
				symbols[s].name = parents[0]+"/"+symbols[s].name;
			}

			symbols[s].doc._dropTag("memberof");
		}
		
		if (symbols[s].desc == "undocumented") {
			if (/(^_|[.\/]_)/.test(symbols[s].name) && !opt.A) {
				continue;
			}
			if (!opt.a && !opt.A) {
				continue;
			}
		}
		
		// is this a member of another object?
		// TODO this relationship may span files, so should move into DocFileGroup?
		var parts = null;
		if (
			symbols[s].name.indexOf("/") > -1
			&& (parts = symbols[s].name.match(/^(.+)\/([^\/]+)$/))
		) {
			var parentName = parts[1].replace(/\//g, ".");
			var childName = parts[2];
			
			symbols[s].alias = symbols[s].name.replace(/\//g, ".");
			symbols[s].name = childName;
			symbols[s].memberof = parentName;

			// is the parent defined?
			var parent = this.getSymbol(parentName);

			if (!parent) LOG.warn("Member '"+childName+"' documented but no documentation exists for parent object '"+parentName+"'.");
			else {
				if (symbols[s].is("OBJECT")) {
					parent.properties.push(symbols[s]);
				}
				if (symbols[s].is("FUNCTION")) {
					parent.methods.push(symbols[s]);
				}
                if (symbols[s].is("EVENT")) {
					parent.events.push(symbols[s]);
				}
			}
		}
		
		this.symbols.push(symbols[s]);
	}
}

/**
 * @param {string} alias The full alias name of the symbol.
 * @return {Symbol}
 */
DocFile.prototype.getSymbol = function(alias) {
	for (var i = 0; i < this.symbols.length; i++) {
		if (this.symbols[i].alias == alias) return this.symbols[i];
	}
    return null;
}