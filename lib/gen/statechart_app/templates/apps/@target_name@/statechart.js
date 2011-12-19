<%= namespace %>.statechart = SC.Statechart.create({

  initialState: 'readyState',
  
  readyState: SC.State.plugin('<%= namespace %>.ReadyState'),
  // someOtherState: SC.State.plugin('<%= namespace %>.SomeOtherState')

});