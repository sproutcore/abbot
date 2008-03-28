/**
 * @fileOverview
 * @name JsParse
 * @author Michael Mathews micmath@gmail.com
 * @url $HeadURL: https://jsdoc-toolkit.googlecode.com/svn/tags/jsdoc_toolkit-1.4.0b/app/JsParse.js $
 * @revision $Id: JsParse.js 329 2007-11-13 00:48:15Z micmath $
 * @license <a href="http://en.wikipedia.org/wiki/MIT_License">X11/MIT License</a>
 *          (See the accompanying README file for full details.)
 */

/**
 * @class Find objects in tokenized JavaScript source code.
 * @constructor
 * @author Michael Mathews <a href="mailto:micmath@gmail.com">micmath@gmail.com</a>
 */
function JsParse() {};

/**
 * Populate the symbols array with symbols found in the
 * given token stream.
 * @param {TokenStream} tokenStream
 */
JsParse.prototype.parse = function(tokenStream) {
	/** 
	 * All symbols found in the tokenStream.
	 * @type Symbol[]
	 */
	this.symbols = [];
	
	/** 
	 * Overview found in the tokenStream.
	 * @type Symbol
	 */
	this.overview = null;
	
	while(tokenStream.next()) {
		if (this._findDocComment(tokenStream)) continue;
		if (this._findFunction(tokenStream)) continue;
		if (this._findVariable(tokenStream)) continue;
	}
}

/**
 * Try to find a JsDoc comment in the tokenStream.
 * @param {TokenStream} ts
 * @return {boolean} Was a JsDoc comment found?
 */
JsParse.prototype._findDocComment = function(ts) {
	if (ts.look().is("JSDOC")) {
		
		ts.look().data = ts.look().data.replace(/@namespace\b/, "@static\n@class");

		var doc = ts.look().data;
		
		
		if (doc.indexOf("/**#") == 0) {
			new Symbol("", [], "META", doc);
			delete ts.tokens[ts.cursor];
			return true;
		}
		else if (/@(projectdescription|(file)?overview)\b/i.test(doc)) {
			this.overview = new Symbol("", [], "FILE", doc);
			delete ts.tokens[ts.cursor];
			return true;
		}
		else if (/@name\s+([a-z0-9_$.]+)\s*/i.test(doc)) {
			this.symbols.push(new Symbol(RegExp.$1, [], SYM.VIRTUAL, doc));
			delete ts.tokens[ts.cursor];
			return true;
		}
		else if (/@scope\s+([a-z0-9_$.]+)\s*/i.test(doc)) {
			var scope = RegExp.$1;
			if (scope) {
				scope = scope.replace(/\.prototype\b/, "/");
				this._onObLiteral(scope, new TokenStream(ts.balance("LEFT_CURLY")));
				return true;
			}
		}
	}
	return false;
}

/**
 * Try to find a function definition in the tokenStream
 * @param {TokenStream} ts
 * @return {boolean} Was a function definition found?
 */
JsParse.prototype._findFunction = function(ts) {
	if (ts.look().is("NAME")) {
		var name = ts.look().data;
		var doc = "";
		var isa = null;
		var body = "";
		var paramTokens = [];
		var params = [];
		
		// like function foo()
		if (ts.look(-1).is("FUNCTION")) {
			isa = SYM.FUNCTION;
			
			if (ts.look(-2).is("JSDOC")) {
				doc = ts.look(-2).data;
			}
			paramTokens = ts.balance("LEFT_PAREN");
			body = ts.balance("LEFT_CURLY");
		}
		
		// like var foo = function()
		else if (ts.look(1).is("ASSIGN") && ts.look(2).is("FUNCTION")) {
			isa = SYM.FUNCTION;
			
			if (ts.look(-1).is("VAR") && ts.look(-2).is("JSDOC")) {
				doc = ts.look(-2).data;
			}
			else if (ts.look(-1).is("JSDOC")) {
				doc = ts.look(-1).data;
			}
			paramTokens = ts.balance("LEFT_PAREN");
			body = ts.balance("LEFT_CURLY");
			
			// like foo = function(n) {return n}(42)
			if (ts.look(1).is("LEFT_PAREN")) {
				isa = SYM.OBJECT;
				
				ts.balance("LEFT_PAREN");
				if (doc) { // we only keep these if they're documented
					name = name.replace(/\.prototype\.?/, "/");
						
					if (!/\/$/.test(name)) { // assigning to prototype of already existing symbol
						this.symbols.push(new Symbol(name, [], isa, doc));
					}
				}
				this._onFnBody(name, new TokenStream(body));
				return true;
			}
		}
		
		// like var foo = new function()
		else if (ts.look(1).is("ASSIGN") && ts.look(2).is("NEW") && ts.look(3).is("FUNCTION")) {
			isa = SYM.OBJECT;
		
			if (ts.look(-1).is("VAR") && ts.look(-2).is("JSDOC")) {
				doc = ts.look(-2).data;
			}
			else if (ts.look(-1).is("JSDOC")) {
				doc = ts.look(-1).data;
			}
			
			paramTokens = ts.balance("LEFT_PAREN");
			body = ts.balance("LEFT_CURLY");
			if (doc) { // we only keep these if they're documented
				name = name.replace(/\.prototype\.?/, "/");
						
				if (!/\/$/.test(name)) { // assigning to prototype of already existing symbol
					this.symbols.push(new Symbol(name, [], isa, doc));
				}
			}
			this._onFnBody(name, new TokenStream(body));
			return true;
		}
		
		if (isa && name) {
			if (isa == SYM.FUNCTION) {
				for (var i = 0; i < paramTokens.length; i++) {
					if (paramTokens[i].is("NAME"))
						params.push(paramTokens[i].data);
				}
			}
			
			// like Foo.bar.prototype.baz = function() {}
			var ns = name;
			if (name.indexOf(".prototype") > 0) {
				isa = SYM.FUNCTION;
				name = name.replace(/\.prototype\.?/, "/");
			}
			
			this.symbols.push(new Symbol(name, params, isa, doc));
			
			if (body) {
				if (ns.indexOf(".prototype") > 0) {
					if (/@constructor\b/.test(doc)) {
						ns = ns.replace(/\.prototype\.?/, "/");
					}
					else {
						ns = ns.replace(/\.prototype\.[^.]+$/, "/");
					}
				}
				this._onFnBody(ns, new TokenStream(body));
			}
			return true;
		}
	}
	return false;
}

/**
 * Try to find a variable definition in the tokenStream
 * @param {TokenStream} ts
 * @return {boolean} Was a variable definition found?
 */
JsParse.prototype._findVariable = function(ts) {
	if (ts.look().is("NAME") && ts.look(1).is("ASSIGN")) {
		// like var foo = 1
		var name = ts.look().data;
		isa = SYM.OBJECT;
		
		var doc;
		if (ts.look(-1).is("JSDOC")) doc = ts.look(-1).data;
		else if (ts.look(-1).is("VAR") && ts.look(-2).is("JSDOC")) doc = ts.look(-2).data;
		name = name.replace(/\.prototype\.?/, "/");
		
		if (doc) { // we only keep these if they're documented
			if (!/\/$/.test(name)) { // assigning to prototype of already existing symbol
				this.symbols.push(new Symbol(name, [], isa, doc));
			}
			if (/@class\b/i.test(doc)) {
				name = name +"/";
			}
		}
		
		// like foo = {
		if (ts.look(2).is("LEFT_CURLY")) {
			this._onObLiteral(name, new TokenStream(ts.balance("LEFT_CURLY")));
		}
		return true;
	}
	return false;
}

/**
 * Handle sub-parsing of the content within an object literal.
 * @private
 * @param {String} nspace The name attached to this object.
 * @param {TokenStream} ts The content of the object literal.
 */
JsParse.prototype._onObLiteral = function(nspace, ts) {
	while (ts.next()) {
		if (this._findDocComment(ts)) {
		
		}
		else if (ts.look().is("NAME") && ts.look(1).is("COLON")) {
			var name = nspace+((nspace.charAt(nspace.length-1)=="/")?"":".")+ts.look().data;
			
			// like foo: function
			if (ts.look(2).is("FUNCTION")) {
				var isa = SYM.FUNCTION;
				var doc = "";
				
				if (ts.look(-1).is("JSDOC")) doc = ts.look(-1).data;
				
				var paramTokens = ts.balance("LEFT_PAREN");
				var params = [];
				for (var i = 0; i < paramTokens.length; i++) {
					if (paramTokens[i].is("NAME"))
						params.push(paramTokens[i].data);
				}
				
				var body = ts.balance("LEFT_CURLY");
				
				// like foo: function(n) {return n}(42)
				if (ts.look(1).is("LEFT_PAREN")) {
					isa = SYM.OBJECT;
					
					ts.balance("LEFT_PAREN");
					//if (doc) { // we only keep these if they're documented
						//name = name.replace(/\.prototype\.?/, "/");
							
						//if (!/\/$/.test(name)) { // assigning to prototype of already existing symbol
						//	this.symbols.push(new Symbol(name, [], isa, doc));
						//}
					//}
					//this._onFnBody(name, new TokenStream(body));
					//return true;
				}
			
				this.symbols.push(new Symbol(name, params, isa, doc));
				
				// find methods in the body of this function
				this._onFnBody(name, new TokenStream(body));
			}
			// like foo: {...}
			else if (ts.look(2).is("LEFT_CURLY")) { // another nested object literal
				if (ts.look(-1).is("JSDOC")) {
					var isa = SYM.OBJECT;
					var doc = ts.look(-1).data;

					this.symbols.push(new Symbol(name, [], isa, doc));
				}
				
				this._onObLiteral(name, new TokenStream(ts.balance("LEFT_CURLY"))); // recursive
			}
			else { // like foo: 1, or foo: "one"
				if (ts.look(-1).is("JSDOC")) { // we only grab these if they are documented
					var isa = SYM.OBJECT;
					var doc = ts.look(-1).data;
					
					this.symbols.push(new Symbol(name, [], isa, doc));
				}
				
				while (!ts.look().is("COMMA")) { // skip to end of RH value ignoring things like bar({blah, blah})
					if (ts.look().is("LEFT_PAREN")) ts.balance("LEFT_PAREN");
					else if (ts.look().is("LEFT_CURLY")) ts.balance("LEFT_CURLY");
					else if (!ts.next()) break;
				}
			}
		}
	}
}

/**
 * Handle sub-parsing of the content within a function body.
 * @private
 * @param {String} nspace The name attached to this function.
 * @param {TokenStream} fs The content of the function body.
 */
JsParse.prototype._onFnBody = function(nspace, fs) {
	while (fs.look()) {
		if (this._findDocComment(fs)) {
		
		}
		else if (fs.look().is("NAME") && fs.look(1).is("ASSIGN")) {
			var name = fs.look().data;
			
			// like this.foo =
			if (name.indexOf("this.") == 0) {
				// like this.foo = function
				if (fs.look(2).is("FUNCTION")) {
					var isa = SYM.FUNCTION;
					var doc = (fs.look(-1).is("JSDOC"))? fs.look(-1).data : "";
					name = name.replace(/^this\./, (nspace+"/").replace("//", "/"))
					
					var paramTokens = fs.balance("LEFT_PAREN");
					var params = [];
					for (var i = 0; i < paramTokens.length; i++) {
						if (paramTokens[i].is("NAME")) params.push(paramTokens[i].data);
					}
					
					body = fs.balance("LEFT_CURLY");

					// like this.foo = function(n) {return n}(42)
					if (fs.look(1).is("LEFT_PAREN")) { // false alarm, it's not really a named function definition
						isa = SYM.OBJECT;
						fs.balance("LEFT_PAREN");
						if (doc) { // we only grab these if they are documented
							this.symbols.push(
								new Symbol(name, [], isa, doc)
							);
						}
						break;
					}

					this.symbols.push(
						new Symbol(name, params, isa, doc)
					);
					
					if (body) {
						this._onFnBody(name, new TokenStream(body)); // recursive
					}
				}
				else {
					var isa = SYM.OBJECT;
					var doc = (fs.look(-1).is("JSDOC"))? fs.look(-1).data : "";
					name = name.replace(/^this\./, (nspace+"/").replace("//", "/"))
						
					if (doc) {
						this.symbols.push(
							new Symbol(name, [], isa, doc)
						);
					}
						
					// like this.foo = { ... }
					if (fs.look(2).is("LEFT_CURLY")) {
						var literal = fs.balance("LEFT_CURLY");
						this._onObLiteral(name, new TokenStream(literal));
					}
				}
			}
			// like <thisfunction>.prototype.foo =
			else if (name.indexOf(nspace+".prototype.") == 0) {
				this._findFunction(fs);
			}
		}
		if (!fs.next()) break;
	}
}
