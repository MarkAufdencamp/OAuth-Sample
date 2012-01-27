class SampleController < ApplicationController

  layout "service"


  def authorizeSampleAccess
    
  end
  
  def retrieveSampleContacts
    @sampleId = "ComputerMark"
    @sampleName = "Mark"
    @sampleContacts = []
    contact = ["Shane","Bartender"]
    @sampleContacts << contact
    contact = ["Evan","Fuckoff"]
    @sampleContacts << contact
  end
  
private

end