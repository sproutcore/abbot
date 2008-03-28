/**
 * @fileOverview A library for finding the parts of JavaScript source code.
 * @name JsToke
 * @author Michael Mathews micmath@gmail.com
 * @url $HeadURL: https://jsdoc-toolkit.googlecode.com/svn/tags/jsdoc_toolkit-1.4.0b/app/JsToke.js $
 * @revision $Id: JsToke.js 213 2007-08-22 10:21:50Z micmath $
 * @license <a href="http://en.wikipedia.org/wiki/MIT_License">X11/MIT License</a>
 *          (See the accompanying README file for full details.)
 */

/** Defines the internal names for tokens. */
var TOKN = {};
TOKN.WHIT = {
	" ":      "SPACE",
	"\f":     "FORMFEED",
	"\t":     "TAB",
	"\u0009": "UNICODE_TAB",
	"\u000A": "UNICODE_NBR",
	"\u0008": "VERTICAL_TAB"
};
TOKN.NEWLINE = {
	"\n":     "NEWLINE",
	"\r":     "RETURN",
	"\u000A": "UNICODE_LF",
	"\u000D": "UNICODE_CR",
	"\u2029": "UNICODE_PS",
	"\u2028": "UNICODE_LS"
};
TOKN.KEYW = {
	"=break":      "BREAK",
	"=case":       "CASE",
	"=catch":      "CATCH",
	"=continue":   "CONTINUE",
	"=default":    "DEFAULT",
	"=delete":     "DELETE",
	"=do":         "DO",
	"=else":       "ELSE",
	"=false":      "FALSE",
	"=finally":    "FINALLY",
	"=for":        "FOR",
	"=function":   "FUNCTION",
	"=if":         "IF",
	"=in":         "IN",
	"=instanceof": "INSTANCEOF",
	"=new":        "NEW",
	"=null":       "NULL",
	"=return":     "RETURN",
	"=switch":     "SWITCH",
	"=this":       "THIS",
	"=throw":      "THROW",
	"=true":       "TRUE",
	"=try":        "TRY",
	"=typeof":     "TYPEOF",
	"=void":       "VOID",
	"=while":      "WHILE",
	"=with":       "WITH",
	"=var":        "VAR"
};

TOKN.PUNC = {
	";":   "SEMICOLON",
	",":   "COMMA",
	"?":   "HOOK",
	":":   "COLON",
	"||":  "OR", 
	"&&":  "AND",
	"|":   "BITWISE_OR",
	"^":   "BITWISE_XOR",
	"&":   "BITWISE_AND",
	"===": "STRICT_EQ", 
	"==":  "EQ",
	"=":   "ASSIGN",
	"!==": "STRICT_NE",
	"!=":  "NE",
	"<<":  "LSH",
	"<=":  "LE", 
	"<":   "LT",
	">>>": "URSH",
	">>":  "RSH",
	">=":  "GE",
	">":   "GT", 
	"++":  "INCREMENT",
	"--":  "DECREMENT",
	"+":   "PLUS",
	"-":   "MINUS",
	"*":   "MUL",
	"/":   "DIV", 
	"%":   "MOD",
	"!":   "NOT",
	"~":   "BITWISE_NOT",
	".":   "DOT",
	"[":   "LEFT_BRACKET",
	"]":   "RIGHT_BRACKET",
	"{":   "LEFT_CURLY",
	"}":   "RIGHT_CURLY",
	"(":   "LEFT_PAREN",
	")":   "RIGHT_PAREN" 
};
TOKN.MATCHING = {
	"LEFT_PAREN": "RIGHT_PAREN",
	"LEFT_CURLY": "RIGHT_CURLY",
	"LEFT_BRACE": "RIGHT_BRACE"
};
TOKN.NUMB    = /^(\.[0-9]|[0-9]+\.|[0-9])[0-9]*([eE][+-][0-9]+)?$/i;
TOKN.HEX_DEC = /^0x[0-9A-F]+$/i;

String.prototype.isWordChar = function() {
	return /^[a-zA-Z0-9$_.]+$/.test(this);
}
String.prototype.isNewline = function() {
	return (typeof TOKN.NEWLINE[this] != "undefined")
}
String.prototype.isSpace = function() {
	return (typeof TOKN.WHIT[this] != "undefined");
}
String.prototype.last = function() {
	return this.charAt[this.length-1];
}

/**
 * @class Extends built-in Array under a new name.
 * @constructor 
 */
var List = function() {
    that = Array.apply(this, arguments);
	
	/**
	 * Get the last item on the list.
	 * @name last
	 * @function
	 * @memberOf List
	 */
    that.last = function() {
    	return this[this.length-1];
    }
    return that;
}

/** 
 * @class A single element of the source code.
 * @constructor
 */
function Token(data, type, name) {
    this.data = data;
    this.type = type;
	this.name = name;
}
Token.prototype.toString = function() { 
    return "<"+this.type+" name=\""+this.name+"\">"+this.data+"</"+this.type+">";
}

/** 
 * Check to see what this token is.
 * @param {string} what Either a name or a token type, like "COMMA" or "PUNC".
 * @return {boolean}
 */
Token.prototype.is = function(what) {
    return this.name === what || this.type === what;
}

/**
 * @class Like a string that you can easily move forward and backward through.
 * @constructor
 */
function TextStream(text) {
	this.text = text;
	this.cursor = 0;
}

/**
 * Return the character n places away.
 * @param {integer} n Positive or negative (defaults to zero), where to look relative to the current cursor position.
 * @return {character}
 */
TextStream.prototype.look = function(n) {
	if (typeof n == "undefined") n = 0;
	
	if (this.cursor+n < 0 || this.cursor+n >= this.text.length) {
		var result = new String("");
		result.eof = true;
		return result;
	}
	return this.text.charAt(this.cursor+n);
}

/**
 * Get the next n characters from the string relative to the current cursor position, and advance the cursor to the new position.
 * @param {integer} n Positive (defaults to one), how many tokens to return.
 * @return {string}
 */
TextStream.prototype.next = function(n) {
	if (typeof n == "undefined") n = 1;
	if (n < 1) return null;
	
	var pulled = "";
	for (var i = 0; i < n; i++) {
		if (this.cursor+i < this.text.length) {
			pulled += this.text.charAt(this.cursor+i);
		}
		else {
			var result = new String("");
			result.eof = true;
			return result;
		}
	}

	this.cursor += n;
	return pulled;
}

/**
 * @class Scan the source code for possible tokens.
 * @constructor
 * @param {string} src The JavaScript source code.
 */
function TokenReader(src){
	this.src = src;
	this.keepDocs = true;
	this.keepWhite = false;
	this.keepComments = false;
};

/**
 * Turn source code into a Token array.
 * @return {List} All Tokens found in the source code.
 */
TokenReader.prototype.tokenize = function() {
	var stream = new TextStream(this.src);
	var tokens = new List();
	
	while (!stream.look().eof) {
		if (this.read_mlcomment(stream, tokens)) continue;
		if (this.read_slcomment(stream, tokens)) continue;
		if (this.read_dbquote(stream, tokens)) continue;
		if (this.read_snquote(stream, tokens)) continue;
		if (this.read_regx(stream, tokens)) continue;
		if (this.read_numb(stream, tokens)) continue;
		if (this.read_punc(stream, tokens)) continue;
		if (this.read_space(stream, tokens)) continue;
		if (this.read_newline(stream, tokens)) continue;
		if (this.read_word(stream, tokens)) continue;
		
		tokens.push(new Token(stream.next(), "TOKN", "UNKNOWN_TOKEN")); // This is an error case.
	}
	return tokens;
}

TokenReader.prototype.read_word = function(stream, tokens) {
	var found = "";
	while (!stream.look().eof && stream.look().isWordChar()) {
		found += stream.next();
	}
	
	if (found === "") {
		return false;
	}
	else {
		var name;
		if ((name = TOKN.KEYW["="+found])) tokens.push(new Token(found, "KEYW", name));
		else tokens.push(new Token(found, "NAME", "NAME"));
		return true;
	}
}
TokenReader.prototype.read_punc = function(stream, tokens) {
	var found = "";
	var name;
	while (!stream.look().eof && TOKN.PUNC[found+stream.look()]) {
		found += stream.next();
	}
	
	if (found === "") {
		return false;
	}
	else {
		tokens.push(new Token(found, "PUNC", TOKN.PUNC[found]));
		return true;
	}
}
TokenReader.prototype.read_space = function(stream, tokens) {
	var found = "";
	
	while (!stream.look().eof && stream.look().isSpace()) {
		found += stream.next();
	}
	
	if (found === "") {
		return false;
	}
	else {
		if (this.collapseWhite) found = " ";
		if (this.keepWhite) tokens.push(new Token(found, "WHIT", "SPACE"));
		return true;
	}
}
TokenReader.prototype.read_newline = function(stream, tokens) {
	var found = "";
	
	while (!stream.look().eof && stream.look().isNewline()) {
		found += stream.next();
	}
	
	if (found === "") {
		return false;
	}
	else {
		if (this.collapseWhite) found = "\n";
		if (this.keepWhite) tokens.push(new Token(found, "WHIT", "NEWLINE"));
		return true;
	}
}
TokenReader.prototype.read_mlcomment = function(stream, tokens) {
	if (stream.look() == "/" && stream.look(1) == "*") {
		var found = stream.next(2);
		
		while (!stream.look().eof && !(stream.look(-1) == "/" && stream.look(-2) == "*")) {
			found += stream.next();
		}
		
		if (/^\/\*\*[^*]/.test(found) && this.keepDocs) tokens.push(new Token(found, "COMM", "JSDOC"));
		else if (this.keepComments) tokens.push(new Token(found, "COMM", "MULTI_LINE_COMM"));
		return true;
	}
	return false;
}
TokenReader.prototype.read_slcomment = function(stream, tokens) {
	var found;
	if (
		(stream.look() == "/" && stream.look(1) == "/" && (found=stream.next(2)))
		|| 
		(stream.look() == "<" && stream.look(1) == "!" && stream.look(2) == "-" && stream.look(3) == "-" && (found=stream.next(4)))
	) {
		
		while (!stream.look().eof && !stream.look().isNewline()) {
			found += stream.next();
		}
		
		if (this.keepComments) {
			tokens.push(new Token(found, "COMM", "SINGLE_LINE_COMM"));
		}
		return true;
	}
	return false;
}
TokenReader.prototype.read_dbquote = function(stream, tokens) {
	if (stream.look() == "\"") {
		// find terminator
		var string = stream.next();
		
		while (!stream.look().eof) {
			if (stream.look() == "\\") {
				if (stream.look(1).isNewline()) {
					do {
						stream.next();
					} while (!stream.look().eof && stream.look().isNewline());
					string += "\\\n";
				}
				else {
					string += stream.next(2);
				}
			}
			else if (stream.look() == "\"") {
				string += stream.next();
				tokens.push(new Token(string, "STRN", "DOUBLE_QUOTE"));
				return true;
			}
			else {
				string += stream.next();
			}
		}
	}
	return false; // error! unterminated string
}
TokenReader.prototype.read_snquote = function(stream, tokens) {
	if (stream.look() == "'") {
		// find terminator
		var string = stream.next();
		
		while (!stream.look().eof) {
			if (stream.look() == "\\") { // escape sequence
				string += stream.next(2);
			}
			else if (stream.look() == "'") {
				string += stream.next();
				tokens.push(new Token(string, "STRN", "SINGLE_QUOTE"));
				return true;
			}
			else {
				string += stream.next();
			}
		}
	}
	return false; // error! unterminated string
}
TokenReader.prototype.read_numb = function(stream, tokens) {
	if (stream.look() === "0" && stream.look(1) == "x") {
		return this.read_hex(stream, tokens);
	}
	
	var found = "";
	
	while (!stream.look().eof && TOKN.NUMB.test(found+stream.look())){
		found += stream.next();
	}
	
	if (found === "") {
		return false;
	}
	else {
		if (/^0[0-7]/.test(found)) tokens.push(new Token(found, "NUMB", "OCTAL"));
		else tokens.push(new Token(found, "NUMB", "DECIMAL"));
		return true;
	}
}
TokenReader.prototype.read_hex = function(stream, tokens) {
	var found = stream.next(2);
	
	while (!stream.look().eof) {
		if (TOKN.HEX_DEC.test(found) && !TOKN.HEX_DEC.test(found+stream.look())) { // done
			tokens.push(new Token(found, "NUMB", "HEX_DEC"));
			return true;
		}
		else {
			found += stream.next();
		}
	}
	return false;
}
TokenReader.prototype.read_regx = function(stream, tokens) {
	if (
		stream.look() == "/"
	 	&& 
	 	(
	 		!tokens.last()
	 		||
			(
				!tokens.last().is("NUMB")
				&& !tokens.last().is("NAME")
				&& !tokens.last().is("RIGHT_PAREN")
				&& !tokens.last().is("RIGHT_BRACKET")
			)
		)
	) {
		var regex = stream.next();
		
		while (!stream.look().eof) {
			if (stream.look() == "\\") { // escape sequence
				regex += stream.next(2);
			}
			else if (stream.look() == "/") {
				regex += stream.next();
				
				while (/[gmi]/.test(stream.look())) {
					regex += stream.next();
				}
				
				tokens.push(new Token(regex, "REGX", "REGX"));
				return true;
			}
			else {
				regex += stream.next();
			}
		}
		// error: unterminated regex
	}
	return false;
}

/**
 * @class Like a array that you can easily move forward and backward through.
 * @constructor
 * @param {List} array The list of tokens to use.
 */
function TokenStream(tokens) {
	this.tokens = (tokens || []);
	this.cursor = -1;
}

/**
 * Return the token n places away from the current position.
 * @param {integer} n Positive or negative (defaults to zero), where to look relative to the current cursor position.
 * @param {boolean} considerWhitespace If whitespace is in the tokenStream they will normally be ignored here, but set this to true if you want to consider whitespace.
 */
TokenStream.prototype.look = function(n, considerWhitespace) {
	if (typeof n == "undefined") n = 0;

	if (considerWhitespace == true) {
		if (this.cursor+n < 0 || this.cursor+n > this.tokens.length) return {};
		return this.tokens[this.cursor+n];
	}
	else {
		var count = 0;
		var i = this.cursor;
		var voidToken = {is: function(){return false;}}
		while (true) {
			if (i < 0 || i > this.tokens.length) return voidToken;
			if (i != this.cursor && (this.tokens[i] === undefined || this.tokens[i].is("SPACE") || this.tokens[i].is("NEWLINE"))) {
				if (n < 0) i--; else i++;
				continue;
			}
			
			if (count == Math.abs(n)) {
				return this.tokens[i];
			}
			count++;
			(n < 0)? i-- : i++;
		}
		return voidToken; // because null isn't an object and caller always expects an object
	}
};

/**
 * Get the next n tokens from the stream relative to the current cursor position, and advance the cursor to the new position.
 * @param {integer} howMany Positive (defaults to one), how many tokens to return.
 */
TokenStream.prototype.next = function(howMany) {
	if (typeof howMany == "undefined") howMany = 1;
	if (howMany < 1) return null;
	var got = [];

	for (var i = 1; i <= howMany; i++) {
		if (this.cursor+i >= this.tokens.length) {
			return null;
		}
		got.push(this.tokens[this.cursor+i]);
	}
	this.cursor += howMany;

	if (howMany == 1) {
		return got[0];
	}
	else return got;
};

/**
 * Get all the tokens between a starting token and the stop token. The stop token will be found considering its balance with 
 * the start token. That is, it must be the one that closes the start token, not necessarily the first stop token.
 * @param {TOKN} start The token to start collecting on, must be present somewhere in the stream ahead of the cursor.
 * @param {TOKN} [stop] The token to stop collecting on, must be present somewhere in the stream ahead of the cursor and after the start token.
 * If this is not given, the matching token to start will be used if it exists. Like ( and ) or { and }.
 */
TokenStream.prototype.balance = function(start, stop) {
	if (!stop) stop = TOKN.MATCHING[start];
	
	var depth = 0;
	var got = [];
	var started = false;
	
	while ((token = this.look())) {
		if (token.is(start)) {
			depth++;
			started = true;
		}
		
		if (started) {
			got.push(token);
		}
		
		if (token.is(stop)) {
			depth--;
			if (depth == 0) return got;
		}
		if (!this.next()) break;
	}
};