class TestSession
  constructor: (@test_elems)->
  selectAll: ->
    @test_elems.find('input[type=checkbox]').prop("checked","checked")
  selectNone: ->
    @test_elems.find('input[type=checkbox]').removeProp("checked")
      


$ ->
  window.testSession = new TestSession($('#test_names'))
