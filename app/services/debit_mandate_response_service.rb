# -*- encoding : UTF-8 -*-
class DebitMandateResponseService
  include POSIX::Spawn


  def initialize(blob)
    @blob      = blob
    @scim_home = Slimpay::SCIM_HOME
  end


  def execute
    command = "LANG=\"en_US.UTF8\" java -Dfile.encoding=UTF-8 \
-Dlog4j.configuration=file:#{@scim_home}scim/log4j.xml \
-Dscim.home=#{@scim_home} \
-jar #{@scim_home}scim/scim.jar \
-response #{@blob} 2>&1"
    text = `#{command}`
    Hash[text.split('&').map { |e| e.split('=') }] if $CHILD_STATUS.success?
  end
end
