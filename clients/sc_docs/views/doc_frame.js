// ==========================================================================
// Docs.DocFrameView
// ==========================================================================

require('core');

Docs.DocFrameView = SC.View.extend({
  
  // This is set to the test you want to run.
  doc: null,
  
  docObserver: function() {
    var doc = this.get('doc') ;
    var url = (doc) ? doc.get('url') : '' ;
    if (url.length > 0) {
      url = "/%@/%@/-docs/data/%@".fmt(window.urlPrefix,Docs.docsController.get('clientName'), url) ;
    }
    
    // make sure we clear out the old document settings if needed.
    var fdoc = (this.rootElement.contentWindow) ? this.rootElement.contentWindow.document : this.rootElement.document ;
    
    // if the document URL is already loaded, then reload it...
    if (url == this.rootElement.src) {
      if (fdoc && fdoc.location) fdoc.location.reload() ;
      
    // otherwise set to the new URL.
    } else {
      this.rootElement.src = url ;
    }
    
  }.observes('doc')
    
}) ;
