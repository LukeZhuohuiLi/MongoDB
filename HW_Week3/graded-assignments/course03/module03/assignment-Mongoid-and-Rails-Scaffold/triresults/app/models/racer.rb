class Racer
  include Mongoid::Document

embeds_one :info, class_name: 'RacerInfo', autobuild: true, as: :parent
#autobuild: build a RacerInfo object when creating a Racer object
 before_create do |racer| 
    racer.info.id = racer.id
 end
 #racer.id == racer_id
end
