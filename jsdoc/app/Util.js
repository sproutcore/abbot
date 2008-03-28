/**
 * @fileOverview
 * @name Util
 * @author Michael Mathews micmath@gmail.com
 * @url $HeadURL: https://jsdoc-toolkit.googlecode.com/svn/tags/jsdoc_toolkit-1.4.0b/app/Util.js $
 * @revision $Id: Util.js 244 2007-09-23 09:42:21Z micmath $
 * @license <a href="http://en.wikipedia.org/wiki/MIT_License">X11/MIT License</a>
 *          (See the accompanying README file for full details.)
 */

/**
 * @class Various utility methods used by JsDoc.
 * @static
 */
Util = {
	/**
	 * Turn a path into just the name of the file.
	 * @static
	 * @param {string} path
	 * @return {string} The fileName portion of the path.
	 */
	fileName: function(path) {
		var nameStart = Math.max(path.lastIndexOf("/")+1, path.lastIndexOf("\\")+1, 0);
		return path.substring(nameStart);
	},
	
	/**
	 * Turn a path into just the directory part.
	 * @static
	 * @param {string} path
	 * @return {string} The directory part of the path.
	 */
	dir: function(path) {
		var nameStart = Math.max(path.lastIndexOf("/")+1, path.lastIndexOf("\\")+1, 0);
		return path.substring(0, nameStart-1);
	},
	
	/**
	 * Get commandline option values.
	 * @static
	 * @param {Array} args Commandline arguments. Like ["-a=xml", "-b", "--class=new", "--debug"]
	 * @param {object} optNames Map short names to long names. Like {a:"accept", b:"backtrace", c:"class", d:"debug"}.
	 * @return {object} Short names and values. Like {a:"xml", b:true, c:"new", d:true}
	 */
	getOptions: function(args, optNames) {
		var opt = {"_": []}; // the unnamed option allows multiple values
		for (var i = 0; i < args.length; i++) {
			var arg = new String(args[i]);
			var name;
			var value;
			if (arg.charAt(0) == "-") {
				if (arg.charAt(1) == "-") { // it's a longname like --foo
					arg = arg.substring(2);
					var m = arg.split("=");
					name = m.shift();
					value = m.shift();
					if (typeof value == "undefined") value = true;
					
					for (var n in optNames) { // convert it to a shortname
						if (name == optNames[n]) {
							name = n;
						}
					}
				}
				else { // it's a shortname like -f
					arg = arg.substring(1);
					var m = arg.split("=");
					name = m.shift();
					value = m.shift();
					if (typeof value == "undefined") value = true;
					
					for (var n in optNames) { // find the matching key
						if (name == n || name+'[]' == n) {
							name = n;
							break;
						}
					}
				}
				if (name.match(/(.+)\[\]$/)) { // it's an array type like n[]
					name = RegExp.$1;
					if (!opt[name]) opt[name] = [];
				}
				
				if (opt[name] && opt[name].push) {
					opt[name].push(value);
				}
				else {
					opt[name] = value;
				}
			}
			else { // not associated with any optname
				opt._.push(args[i]);
			}
		}
		return opt;
	}
}