// ==========================================================================
// Docs
// ==========================================================================

function main() {
  SC.page.awake() ;

  // SproutCore loads the files from a pre-generated location unlike when
  // this apps runs on your local box, hence this logic.
  if (window.location.hostname.toString().indexOf('sproutcore.com') >= 0) {
    var clientRoot = 'sproutcore/-docs' ;
    var clientName = 'sproutcore' ;   
    var canRebuild = NO ; 
  } else {
    var clientRoot = window.location.pathname.toString().replace(/-docs\/.*/,'-docs').substr(1,window.location.pathname.length);
    var clientName = clientRoot.match(/([^\/]+)\/-docs/)[1];
    var canRebuild = YES ; 
  }

  Docs.docsController.set('selection',[]) ;
  Docs.docsController.set('clientRoot', clientRoot) ;
  Docs.docsController.set('clientName', clientName) ;
  Docs.docsController.set('canRebuild', canRebuild) ;
  Docs.docsController.reloadDocs() ;
} ;

