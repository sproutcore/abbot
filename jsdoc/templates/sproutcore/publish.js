// This is the orginial function from Stuart Langridge at http://www.kryogenix.org/
// This is the update function from Jeff Minard - http://www.jrm.cc/
function superTextile(s) {

  // CAJ - First, strip out extra newlines and whitespace at the start
  // of comments.  This will yield more appropriate text for formatting.
  s = s.split("\n").map(function(l) { return ((l=='') || (l.match(/^\s+$/))) ? "" : l.replace(/^\s+/,'') ; }).join("\n") ;

  var r = s;
  // quick tags first
  qtags = [ ['\\*', '\\*', 'strong'],
            ['\\?\\?', '\\?\\?', 'cite'],
            ['\\+', '\\+', 'ins'],  //fixed
            ['~', '~', 'sub'],   
            ['\\^', '\\^', 'sup'], // me
            ['{{{', '}}}', 'code']];

  for (var i=0;i<qtags.length;i++) {
    var ttag_o = qtags[i][0], ttag_c = qtags[i][1], htag = qtags[i][2];
    re = new RegExp(ttag_o+'\\b(.+?)\\b'+ttag_c,'g');
    r = r.replace(re,'<'+htag+'>'+'$1'+'</'+htag+'>');
  };

  // underscores count as part of a word, so do them separately
  re = new RegExp('\\b_(.+?)_\\b','g');
  r = r.replace(re,'<em>$1</em>');

  //jeff: so do dashes
  re = new RegExp('[\s\n]-(.+?)-[\s\n]','g');
  r = r.replace(re,'<del>$1</del>');

  // links
  re = new RegExp('"\\b(.+?)\\(\\b(.+?)\\b\\)":([^\\s]+)','g');
  r = r.replace(re,'<a href="$3" title="$2">$1</a>');

  re = new RegExp('"\\b(.+?)\\b":([^\\s]+)','g');
  r = r.replace(re,'<a href="$2">$1</a>');

  // images
  re = new RegExp('!\\b(.+?)\\(\\b(.+?)\\b\\)!','g');
  r = r.replace(re,'<img src="$1" alt="$2">');
  re = new RegExp('!\\b(.+?)\\b!','g');
  r = r.replace(re,'<img src="$1">');

  // block level formatting
  lines = r.split('\n');
  out = [] ;
  nr = '';
  var incode = 0 ;
  var cur_block = [] ; // collect lines into a block before processing them.
  for (var i=0;i<lines.length;i++) {
    var line = lines[i].replace(/\s*$/,'');
    changed = 0;

    // handle incode behavior.
    if (incode) {

      // Look for end closing bracket and process it.
      if (line.match(/^\s*}}}\s*$/)) {
        incode = 0 ;
        out.push("<p class=\"code\"><code>" + cur_block.join("<br />") + "</code></p>") ;
        cur_block = [] ;

      // otherwise, just add the line to the current block, escaping HTML entities
      } else {
        cur_block.push(line.split("&").join("&amp;").split("<").join("&lt;").split(">").join("&gt;")) ;
      }

    // for normal text, look for line-level items to replace.  If no
    // replacement is found, then add the line to the current block.
    } else {

      // an empty line means we should end the current paragraph
      if ((line == '') || line.match(/^\s+$/)) {
        changed = 1 ;
        line = '' ;

      // convert bq. => blockquote.
      } else if (line.search(/^\s*bq\.\s+/) != -1) { 
        line = line.replace(/^\s*bq\.\s+/,'\t<blockquote>')+'</blockquote>'; 
        changed = 1; 

      // convert h* => heading
      } else if (line.search(/^\s*h[1|2|3|4|5|6]\.\s+/) != -1) { 
        line = line.replace(/^\s*h([1|2|3|4|5|6])\.(.+)/, '<h$1>$2</h$1>');
        changed = 1; 

      // convert - to bulletted list.  liu tag will be fixed later.
      } else if (line.search(/^\s*-\s+/) != -1) { 
        line = line.replace(/^\s*-\s+/,'\t<liu>') + '</liu>'; changed = 1;
        changed = 1;

      // convert * to bulletted list.  liu tag will be fixed later.
      } else if (line.search(/^\s*\*\s+/) != -1) { 
        line = line.replace(/^\s*\*\s+/,'\t<liu>') + '</liu>'; changed = 1;
        changed = 1;

      // convert # to numbered list. lio tag will be fixed later. 
      } else if (line.search(/^\s*#\s+/) != -1) { 
        line = line.replace(/^\s*#\s+/,'\t<lio>') + '</lio>'; changed = 1; 
        changed = 1;

      // open code tag will start code
      } else if (line.match(/^\s*\{\{\{\s*$/)) {
        incode++ ;
        line = '' ;
        changed = 1;
      }

      // if the line was changed, the emit the current block as a paragraph
      // and emit the line itself.  Otherwise, just push the line into the
      // current block.
      if (changed > 0) {
        if (cur_block.length > 0) {
          out.push("<p>" + cur_block.join(" ") + '</p>') ;
          cur_block = [] ;
        }
        out.push(line) ;
      } else {
        cur_block.push(line) ;
      }
    }
  }

  // done.  if there are any lines left, in the current block, emit it.
  if (cur_block.length > 0) {
    out.push("<p>" + cur_block.join(" ") + '</p>') ;
    cur_block = [] ;
  }

  // Second pass to do lists.  This will wrap the lists in <li> | <ol> tags.
  inlist = 0; 
  listtype = '';
  for (var i=0;i<out.length;i++) {
    line = out[i];
    var addin = null ;

    if (inlist && listtype == 'ul' && !line.match(/^\t<liu/)) { 
      addin = '</ul>\n'; inlist = 0; 
    }

    if (inlist && listtype == 'ol' && !line.match(/^\t<lio/)) { 
      addin = '</ol>\n'; inlist = 0; 
    }

    if (!inlist && line.match(/^\t<liu/)) { 
      line = '<ul>' + line; inlist = 1; listtype = 'ul'; 
    }

    if (!inlist && line.match(/^\t<lio/)) { 
      line = '<ol>' + line; inlist = 1; listtype = 'ol'; 
    }

    if (addin) line = addin + line ;
    out[i] = line;
  }

  // Now we can join the string. Yay!
  r = out.join('\n');

  // jeff added : will correctly replace <li(o|u)> AND </li(o|u)>
  r = r.replace(/li[o|u]>/g,'li>');

  return r;
};

function publish(symbolSet) {
  publish.conf = {  // trailing slash expected for dirs
    ext: ".html",
    outDir: JSDOC.opt.d || SYS.pwd+"../out/jsdoc/",
    templatesDir: SYS.pwd+"../templates/sproutcore/",
    symbolsDir: "symbols/",
    srcDir: "symbols/src/"
  };
  
  
  if (JSDOC.opt.s && defined(Link) && Link.prototype._makeSrcLink) {
    Link.prototype._makeSrcLink = function(srcFilePath) {
      return "&lt;"+srcFilePath+"&gt;";
    }
  }
  
  IO.mkPath((publish.conf.outDir+"symbols/src").split("/"));
    
  // used to check the details of things being linked to
  Link.symbolSet = symbolSet;

  try {
    var classTemplate = new JSDOC.JsPlate(publish.conf.templatesDir+"class.tmpl");
    var classesTemplate = new JSDOC.JsPlate(publish.conf.templatesDir+"allclasses.tmpl");
  }
  catch(e) {
    print(e.message);
    quit();
  }
  
  // filters
  function hasNoParent($) {return ($.memberOf == "")}
  function isaFile($) {return ($.is("FILE"))}
  function isaClass($) {return ($.is("CONSTRUCTOR") || $.isNamespace)}
  
  var symbols = symbolSet.toArray();
  
  var files = JSDOC.opt.srcFiles;
   for (var i = 0, l = files.length; i < l; i++) {
     var file = files[i];
     var srcDir = publish.conf.outDir + "symbols/src/";
    makeSrcFile(file, srcDir);
   }
   
   var classes = symbols.filter(isaClass).sort(makeSortby("alias"));
  
  Link.base = "../";
   publish.classesIndex = classesTemplate.process(classes); // kept in memory
  
  for (var i = 0, l = classes.length; i < l; i++) {
    var symbol = classes[i];
    var output = "";
    output = classTemplate.process(symbol);
    
    IO.saveFile(publish.conf.outDir+"symbols/", symbol.alias+publish.conf.ext, output);
  }
  
  // regenrate the index with different relative links
  Link.base = "";
  publish.classesIndex = classesTemplate.process(classes);
  
  try {
    var classesindexTemplate = new JSDOC.JsPlate(publish.conf.templatesDir+"index.tmpl");
  }
  catch(e) { print(e.message); quit(); }
  
  var classesIndex = classesindexTemplate.process(classes);
  // IO.saveFile(publish.conf.outDir, "index"+publish.conf.ext, classesIndex);
  IO.saveFile(publish.conf.outDir, "classes.js", classesIndex);
  classesindexTemplate = classesIndex = classes = null;
  
  try {
    var fileindexTemplate = new JSDOC.JsPlate(publish.conf.templatesDir+"allfiles.tmpl");
  }
  catch(e) { print(e.message); quit(); }
  
  var documentedFiles = symbols.filter(isaFile);
  var allFiles = [];
  
  for (var i = 0; i < files.length; i++) {
    allFiles.push(new JSDOC.Symbol(files[i], [], "FILE", new JSDOC.DocComment("/** */")));
  }
  
  for (var i = 0; i < documentedFiles.length; i++) {
    var offset = files.indexOf(documentedFiles[i].alias);
    allFiles[offset] = documentedFiles[i];
  }
    
  allFiles = allFiles.sort(makeSortby("name"));

  var filesIndex = fileindexTemplate.process(allFiles);
  IO.saveFile(publish.conf.outDir, "files"+publish.conf.ext, filesIndex);
  fileindexTemplate = filesIndex = files = null;
}


/** Just the first sentence. */
function summarize(desc) {
  if (typeof desc != "undefined")
    return desc.match(/([\w\W]+?\.)[^a-z0-9]/i)? RegExp.$1 : desc;
}

/** make a symbol sorter by some attribute */
function makeSortby(attribute) {
  return function(a, b) {
    if (a[attribute] != undefined && b[attribute] != undefined) {
      a = a[attribute].toLowerCase();
      b = b[attribute].toLowerCase();
      if (a < b) return -1;
      if (a > b) return 1;
      return 0;
    }
  }
}

function include(path) {
  var path = publish.conf.templatesDir+path;
  return IO.readFile(path);
}

function makeSrcFile(path, srcDir, name) {
  if (JSDOC.opt.s) return;
  
  if (!name) {
    name = path.replace(/\.\.?[\\\/]/g, "").replace(/[\\\/]/g, "_");
    name = name.replace(/\:/g, "_");
  }
  
  var src = {path: path, name:name, charset: IO.encoding, hilited: ""};
  
  if (defined(JSDOC.PluginManager)) {
    JSDOC.PluginManager.run("onPublishSrc", src);
  }

  if (src.hilited) {
    IO.saveFile(srcDir, name+publish.conf.ext, src.hilited);
  }
}

function makeSignature(params) {
  if (!params) return "()";
  var signature = "("
  +
  params.filter(
    function($) {
      return $.name.indexOf(".") == -1; // don't show config params in signature
    }
  ).map(
    function($) {
      return $.name;
    }
  ).join(", ")
  +
  ")";
  return signature;
}

/** Find symbol {@link ...} strings in text and turn into html links */
function resolveLinks(str, from) {
  str = str.replace(/\{@link ([^} ]+) ?\}/gi,
    function(match, symbolName) {
      return new Link().toSymbol(symbolName);
    }
  );
  
  return str;
}