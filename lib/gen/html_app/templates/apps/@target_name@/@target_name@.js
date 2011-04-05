// ==========================================================================
// Project:   <%= namespace %>
// Copyright: ©<%= Time.now.year %> My Company, Inc.
// ==========================================================================
/*globals <%= namespace %> */

<%= namespace %> = SC.Application.create();

SC.ready(function() {
  <%= namespace %>.mainPane = SC.TemplatePane.append({
    layerId: '<%= target_name %>',
    templateName: '<%= target_name %>'
  });
});
