/**
  @constructor
  @param [opt] Used to override the commandline options. Useful for testing.
  @version $Id: JsDoc.js 592 2008-05-09 07:43:33Z micmath $
*/
JSDOC.JsDoc = function(/**object*/ opt) {
  if (opt) {
    JSDOC.opt = opt;
  }
  
  // the -c option: use a configuration file
  if (JSDOC.opt.c) {
    eval("JSDOC.conf = " + IO.readFile(JSDOC.opt.c));
    
    LOG.inform("Using configuration file at '"+JSDOC.opt.c+"'.");
    
    for (var c in JSDOC.conf) {
      if (c !== "D" && !defined(JSDOC.opt[c])) { // commandline overrules config file
        JSDOC.opt[c] = JSDOC.conf[c];
      }
    }
    
    if (typeof JSDOC.conf["_"] != "undefined") {
      JSDOC.opt["_"] = JSDOC.opt["_"].concat(JSDOC.conf["_"]);
    }
    
    LOG.inform("With configuration: ");
    for (var o in JSDOC.opt) {
      LOG.inform("    "+o+": "+JSDOC.opt[o]);
    }
  }
  
  if (JSDOC.opt.h) {
    JSDOC.usage();
    quit();
  }
  
  // defend against options that are not sane 
  if (JSDOC.opt._.length == 0) {
    LOG.warn("No source files to work on. Nothing to do.");
    quit();
  }
  if (JSDOC.opt.t === true || JSDOC.opt.d === true) {
    JSDOC.usage();
  }
  
  if (typeof JSDOC.opt.d == "string") {
    if (!JSDOC.opt.d.charAt(JSDOC.opt.d.length-1).match(/[\\\/]/)) {
      JSDOC.opt.d = JSDOC.opt.d+"/";
    }
    LOG.inform("Output directory set to '"+JSDOC.opt.d+"'.");
    IO.mkPath(JSDOC.opt.d);
  }
  if (JSDOC.opt.e) IO.setEncoding(JSDOC.opt.e);
  
  // the -r option: scan source directories recursively
  if (typeof JSDOC.opt.r == "boolean") JSDOC.opt.r = 10;
  else if (!isNaN(parseInt(JSDOC.opt.r))) JSDOC.opt.r = parseInt(JSDOC.opt.r);
  else JSDOC.opt.r = 1;
  
  // the -D option: define user variables
  var D = {};
  if (JSDOC.opt.D) {
    for (var i = 0; i < JSDOC.opt.D.length; i++) {
      var defineParts = JSDOC.opt.D[i].split(":", 2);
      if (defineParts) D[defineParts[0]] = defineParts[1];
    }
  }
  JSDOC.opt.D = D;
  // combine any conf file D options with the commandline D options
  if (defined(JSDOC.conf)) for (var c in JSDOC.conf.D) {
     if (!defined(JSDOC.opt.D[c])) {
       JSDOC.opt.D[c] = JSDOC.conf.D[c];
     }
   }

  // Load additional file handlers
  // the -H option: filetype handlers
  JSDOC.handlers = {};
/*  
  if (JSDOC.opt.H) {
    for (var i = 0; i < JSDOC.opt.H.length; i++) {
      var handlerDef = JSDOC.opt.H[i].split(":");
      LOG.inform("Adding '." + handlerDef[0] + "' content handler from handlers/" + handlerDef[1] + ".js");
      IO.include("handlers/" + handlerDef[1] + ".js");
      if (!eval("typeof "+handlerDef[1])) {
        LOG.warn(handlerDef[1] + "is not defined in "+handlerDef[1] + ".js");
      }
      else {
        JSDOC.handlers[handlerDef[0]] = eval(handlerDef[1]);
      }
    }
  }
*/  
  // Give plugins a chance to initialize
  if (defined(JSDOC.PluginManager)) {
    JSDOC.PluginManager.run("onInit", this);
  }

  JSDOC.opt.srcFiles = this._getSrcFiles();
  this._parseSrcFiles();
  //var handler = symbols.handler;
  this.symbolSet = JSDOC.Parser.symbols;
  //this.symbolGroup.handler = handler;
}

/**
  Retrieve source file list.
  @returns {String[]} The pathnames of the files to be parsed.
 */
JSDOC.JsDoc.prototype._getSrcFiles = function() {
  this.srcFiles = [];
  
  var ext = ["js"];
  if (JSDOC.opt.x) {
    ext = JSDOC.opt.x.split(",").map(function($) {return $.toLowerCase()});
  }
  
  for (var i = 0; i < JSDOC.opt._.length; i++) {
    this.srcFiles = this.srcFiles.concat(
      IO.ls(JSDOC.opt._[i], JSDOC.opt.r).filter(
        function($) {
          var thisExt = $.split(".").pop().toLowerCase();
          return (ext.indexOf(thisExt) > -1 || thisExt in JSDOC.handlers); // we're only interested in files with certain extensions
        }
      )
    );
  }
  
  return this.srcFiles;
}

JSDOC.JsDoc.prototype._parseSrcFiles = function() {
  JSDOC.Parser.init();
  for (var i = 0, l = this.srcFiles.length; i < l; i++) {
    var srcFile = this.srcFiles[i];
  
    try {
      var src = IO.readFile(srcFile);
    }
    catch(e) {
      LOG.warn("Can't read source file '"+srcFile+"': "+e.message);
    }
  
    var tr = new JSDOC.TokenReader();
    var ts = new JSDOC.TokenStream(tr.tokenize(new JSDOC.TextStream(src)));
  
    JSDOC.Parser.parse(ts, srcFile);
  
    // try {
    //   LOG.warn("Processing " + srcFile);
    //   var dump = [];
    //   var sym = null;
    // 
    //   for (var idx = 0, len = syms.length; idx < len; idx++) {
    //       sym = syms[idx];
    //       dump.push('"' + sym.alias + '": ' + sym.serialize());
    //       IO.saveFile(JSDOC.opt.d + 'cache/', JSDOC.cacheName(srcFile), '{' + dump.join(',') + '}');
    //   }
    // } catch(e) {
    //   LOG.warn('problem dumping cache file for ' + srcFile + ': ' + e);
    // }
  }
  JSDOC.Parser.finish();
}

JSDOC.cacheName = function(path) {
  var parts = path.split('/') ;
  
  var rootIndex = parts.indexOf('frameworks') ;
  if (rootIndex < 0) rootIndex = parts.indexOf('clients') ;
  
  if (rootIndex < 0) {
    LOG.warn('bad srcPath passed to JSDOC.cacheName');
    return parts[parts.length - 2] ;
  }
  else {
    return parts.slice(rootIndex, parts.length).join('.') ;
  }
}
