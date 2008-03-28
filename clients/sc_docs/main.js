// ==========================================================================
// Docs
// ==========================================================================

function main() {
  SC.page.awake() ;
  
  console.log('main') ;
  var clientRoot = window.location.pathname.toString().replace(/-docs\/.*/,'-docs').substr(1,window.location.pathname.length);
  var clientName = clientRoot.match(/([^\/]+)\/-docs/)[1];
  Docs.hidePanels() ;
  Docs.docsController.set('selection',[]) ;
  Docs.docsController.set('clientRoot', clientRoot) ;
  Docs.docsController.set('clientName', clientName) ;
  Docs.docsController.reloadDocs() ;
} ;

Docs.hidePanels = function() {
  SC.page.get('warningPanel').set('isVisible', false) ;
  SC.page.get('noDocsPanel').set('isVisible',false) ;
} ;
