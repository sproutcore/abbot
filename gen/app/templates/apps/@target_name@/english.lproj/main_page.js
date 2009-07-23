// ==========================================================================
// Project:   <%= namespace %> - mainPage
// Copyright: ©<%= Time.now.year %> My Company, Inc.
// ==========================================================================
/*globals <%= namespace %> */

// This page describes the main user interface for your application.  
<%= namespace %>.mainPage = SC.Page.design({

  // The main pane is made visible on screen as soon as your app is loaded.
  // Add childViews to this pane for views to display immediately on page 
  // load.
  mainPane: SC.MainPane.design({
    childViews: 'labelView'.w(),
    
    labelView: SC.LabelView.design({
      layout: { centerX: 0, centerY: 0, width: 100, height: 18 },
      tagName: "h1", value: "Hello World"
    })
  })

});
