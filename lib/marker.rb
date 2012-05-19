class Marker
  def self.mark(msg, logger = ActiveRecord::Base.logger)
    start = Time.now
    logger.info("#{start} --> starting #{msg} from #{caller[2]}:#{caller[1]}")
    result = yield
    finish = Time.now
    logger.info("#{finish} --< finished #{msg} --- #{"%2.3f sec" % (finish - start)}")
    result
  end
end
