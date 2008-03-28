require("app/JsHilite.js");

function basename(filename) {
  filename.match(/([^\/\\]+)\.[^\/\\]+$/);
  return RegExp.$1;
}

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
        
      // otherwise, just add the line to the current block
      } else {
        cur_block.push(line) ;
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
} ;

function publish(fileGroup, context) {
  var classTemplate = new JsPlate(context.t+"class.tmpl");
  var indexTemplate = new JsPlate(context.t+"index.tmpl");
  
  var allFiles = {};
  var allClasses = {};
  var globals = {methods:[], properties:[], alias:"GLOBALS", isStatic:true};
  
  for (var i = 0; i < fileGroup.files.length; i++) {
    var file_basename = basename(fileGroup.files[i].filename);
    var file_srcname = file_basename+".src.html";
    
    for (var s = 0; s < fileGroup.files[i].symbols.length; s++) {
      if (fileGroup.files[i].symbols[s].isa == "CONSTRUCTOR") {
        var thisClass = fileGroup.files[i].symbols[s];
        // sort inherited methods by class
        var inheritedMethods = fileGroup.files[i].symbols[s].getInheritedMethods();
        if (inheritedMethods.length > 0) {
          thisClass.inherited = {};
          for (var n = 0; n < inheritedMethods.length; n++) {
            if (! thisClass.inherited[inheritedMethods[n].memberof]) thisClass.inherited[inheritedMethods[n].memberof] = [];
            thisClass.inherited[inheritedMethods[n].memberof].push(inheritedMethods[n]);
          }
        }
        
        thisClass.name = fileGroup.files[i].symbols[s].alias;
        thisClass.source = file_srcname;
        thisClass.filename = fileGroup.files[i].filename;
        thisClass.docs = thisClass.name+".html";
        
        if (!allClasses[thisClass.name]) allClasses[thisClass.name] = [];
        allClasses[thisClass.name].push(thisClass);
      }
      else if (fileGroup.files[i].symbols[s].alias == fileGroup.files[i].symbols[s].name) {
        if (fileGroup.files[i].symbols[s].isa == "FUNCTION") {
          globals.methods.push(fileGroup.files[i].symbols[s]);
        }
        else {
          globals.properties.push(fileGroup.files[i].symbols[s]);
        }
      }
    }
    
    if (!allFiles[fileGroup.files[i].path]) {
      var hiliter = new JsHilite(IO.readFile(fileGroup.files[i].path), JsDoc.opt.e);
      IO.saveFile(context.d, file_srcname, hiliter.hilite());
    }
    fileGroup.files[i].source = file_srcname;
    allFiles[fileGroup.files[i].path] = true;
  }
  
  for (var c in allClasses) {
    outfile = c+".html";
    allClasses[c].outfile = outfile;
    var output = classTemplate.process(allClasses[c]);
    IO.saveFile(context.d, outfile, output);
  }
  
  output = classTemplate.process([globals]);
  IO.saveFile(context.d, "globals.html", output);
  
  var output = indexTemplate.process(allClasses);
  IO.saveFile(context.d, "classes.js", output);
  IO.copyFile(context.t+"index.html", context.d);
  IO.copyFile(context.t+"splash.html", context.d);
  IO.copyFile(context.t+"default.css", context.d) ;
  IO.copyFile(context.t+"prototype.js", context.d) ;
}
