// ==========================================================================
// <%= namespace %> - mainPage
// copyright ©<%= Time.now.year %> My Company, Inc.
// ==========================================================================
/*globals <%= namespace %> */

// This page describes the main user interface for your application.  
<%= namespace %>.mainPage = SC.Page.design({

  // The main pane is made visible on screen as soon as your app is loaded.
  // Add childViews to this pane for views to display immediately on page 
  // load.
  mainPane: SC.MainPane.design()
    .childView(SC.LabelView.design({
      tagName: "h1", value: "Hello World"
    }))

});
