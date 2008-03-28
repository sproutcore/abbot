/**
 * @fileOverview
 * @name Doclet
 * @author Michael Mathews micmath@gmail.com
 * @url $HeadURL: https://jsdoc-toolkit.googlecode.com/svn/tags/jsdoc_toolkit-1.4.0b/app/Doclet.js $
 * @revision $Id: Doclet.js 295 2007-11-11 01:09:02Z micmath $
 * @license <a href="http://en.wikipedia.org/wiki/MIT_License">X11/MIT License</a>
 *          (See the accompanying README file for full details.)
 */
 
/**
 * @class Represents a collection of DocTags.
 * @constructor
 * @author Michael Mathews <a href="mailto:micmath@gmail.com">micmath@gmail.com</a>
 * @param {string} comment The entire documentation comment. The openening slash-star-star and
 * closing star-slash are optional. An untagged string at the start automatically gets a "desc" tag.
 */
function Doclet(comment) {
	var src = Doclet.unwrapComment(comment);
	var tagTexts = src.split(/(^|[\r\f\n])\s*@/);
	
	this.tags =
		tagTexts.filter(function(el){return el.match(/^\w/)})
		.map(function(el){return new DocTag(el)});
	
	var paramParent = "config"; // default
	for(var i = 0; i < this.tags.length; i++) {
		if (this.tags[i].title == "param") paramParent = this.tags[i].name;
		if (this.tags[i].title == "config") {
			this.tags[i].name = paramParent+"."+this.tags[i].name;
			this.tags[i].title = "param"
		}
	}
}

/**
 * Remove the slashes and stars from a doc comment.
 */
Doclet.unwrapComment = function(comment) {
	if (!comment) comment = "/** @desc undocumented */";

	var unwrapped = comment.replace(/(^\/\*\*|\*\/$)/g, "").replace(/^\s*\* ?/gm, "");
	if (unwrapped.match(/^\s*[^@\s]/)) unwrapped = "@desc "+unwrapped;
	return unwrapped;
}

/**
 * Get every DocTag with the given title.
 * @param {string} tagTitle
 * @return {DocTag[]}
 */
Doclet.prototype.getTag = function(tagTitle) {
	return this.tags.filter(function(el){return el.title == tagTitle});
}

/**
 * Remove from this Doclet every DocTag with the given title.
 * @private
 * @param {string} tagTitle
 */
Doclet.prototype._dropTag = function(tagTitle) {
	this.tags = this.tags.filter(function(el){return el.title != tagTitle});
}
