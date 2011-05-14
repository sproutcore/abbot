<%= copyright_block(namespace) %>
/*globals <%= namespace %> */

// This is the JavaScript representation of your theme.
//
// You don't have to create the whole theme on your own, though:
// this theme is currently based on SproutCore's Ace theme.
//
// NOTE: if you want to change the theme this one is based on, don't
// forget to change the :css_theme property in your buildfile.
<%= namespace %> = SC.AceTheme.create({
  name: '<%= css_name %>'
});

// To let apps use your theme, SproutCore must know where to find it.
SC.Theme.addTheme(<%= namespace %>);

// You do not need to set it as a default theme. Apps should set the
// SC.defaultTheme variable. Usually, apps will create their own theme
// and base it on yours.
