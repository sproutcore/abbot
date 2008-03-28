/**
 * @fileOverview
 * @name DocTag
 * @author Michael Mathews micmath@gmail.com
 * @url $HeadURL: https://jsdoc-toolkit.googlecode.com/svn/tags/jsdoc_toolkit-1.4.0b/app/DocTag.js $
 * @revision $Id: DocTag.js 334 2007-11-13 19:52:49Z micmath $
 * @license <a href="http://en.wikipedia.org/wiki/MIT_License">X11/MIT License</a>
 *          (See the accompanying README file for full details.)
 */
 
 /**
  * @class Represents a tag within a doclet.
  * @author Michael Mathews <a href="mailto:micmath@gmail.com">micmath@gmail.com</a>
  * @constructor
  * @param {string} src line(s) of text following the @ character
  */
function DocTag(src) {
	/**
	 * Like @title
	 * @type string
	 */
	this.title = "";
	
	/**
	 * Like @title {type}
	 * @type string
	 */
	this.type = "";
	
	/**
	 * Like @title {type}? name, though this is only recognized in tags with a title of "param" or "property."
	 * @type string
	 */
	this.name = "";
	
	/**
	 * Like @title {type}? name? description goes here...
	 * @type string
	 */
	this.desc = "";
	
	if (typeof(src) != "undefined") {
		var parts = src.match(/^(\S+)(?:\s+\{\s*([\S\s]+?)\s*\})?\s*([\S\s]*\S)?/);
		
		this.title = (parts[1].toLowerCase() || "");
		this.type = (parts[2] || "");
	
		if (this.type) this.type = this.type.replace(/\s*(,|\|\|?)\s*/g, ", ");
		this.desc = (parts[3] || "");
		
		// should be @type foo but we'll accept @type {foo} too
		if (this.title == "type") {
			if (this.type) this.desc = this.type;
			
			// should be @type foo, bar, baz but we'll accept @type foo|bar||baz too
			if (this.desc) {
				this.desc = this.desc.replace(/\s*(,|\|\|?)\s*/g, ", ");
			}
		}
		
		var syn;
		if ((syn = DocTag.synonyms["="+this.title])) this.title = syn;
		
		if (this.desc) {
			if (this.title == "param") { // long tags like {type} [name] desc
				var m = this.desc.match(/^\s*(\[?)([a-zA-Z0-9.$_]+)(\]?)(?:\s+\{\s*([\S\s]+?)\s*\})?(?:\s+([\S\s]*\S))?/);
				if (m) {
					this.isOptional = (!!m[1] && !!m[3]); // bracketed name means optional
					this.name = (m[2] || "");
					this.type = (m[4] || this.type);
					this.desc = (m[5] || "");
				}
			}
			else if (this.title == "property") {
				m = this.desc.match(/^\s*([a-zA-Z0-9.$_]+)(?:\s+([\S\s]*\S))?/);
				if (m) {
					this.name = (m[1] || "");
					this.desc = (m[2] || "");
				}
			}
			else if (this.title == "config") {
				m = this.desc.match(/^\s*(\[?)([a-zA-Z0-9.$_]+)(\]?)(?:\s+([\S\s]*\S))?/);
				if (m) {
					this.isOptional = (!!m[1] && !!m[3]); // bracketed name means optional
					this.name = (m[2] || "");
					this.desc = (m[4] || "");
				}
			}
		}
	}
}

/**
 * Used to make various JsDoc tags compatible with JsDoc Toolkit.
 * @memberOf DocTag
 */
DocTag.synonyms = {
	"=member":             "memberof",
	"=description":        "desc",
	"=exception":          "throws",
	"=argument":           "param",
	"=returns":            "return",
	"=classdescription":   "class",
	"=fileoverview":       "overview",
	"=extends":            "augments"
}

DocTag.prototype.toString = function() {
	return this.desc;
}
