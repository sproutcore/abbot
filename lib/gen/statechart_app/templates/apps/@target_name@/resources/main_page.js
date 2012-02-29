<%= copyright_block("#{namespace} - mainPage") %>
/*globals <%= namespace %> */

// This page describes the main user interface for your application.  
<%= namespace %>.mainPage = SC.Page.create({

  // The main pane is made visible on screen as soon as your app is loaded.
  // Add childViews to this pane for views to display immediately on page 
  // load.
  mainPane: SC.MainPane.extend({
    childViews: 'labelView'.w(),
    
    labelView: SC.LabelView.extend({
      layout: { centerX: 0, centerY: 0, width: 200, height: 18 },
      textAlign: SC.ALIGN_CENTER,
      tagName: "h1", 
      value: "Welcome to SproutCore!"
    })
  })

});
