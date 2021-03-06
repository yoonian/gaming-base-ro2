module Ragnarok2
  class Citizen < ActiveRecord::Base
    searchable
    
    validates :citizen_id,
        :uniqueness => { :case_sensitive => false },
        :allow_blank => false,
        :numericality => { :only_integer => true }

    validates :name, :presence => true

    default_scope includes(:name)
    belongs_to :name,
            :foreign_key => :string_name_id,
            :primary_key => :citizen_id,
            :class_name => "Ragnarok2::Translations::CitizenName"

    default_scope includes(:job_name)
    belongs_to :job_name,
            :foreign_key => :string_job_name_id,
            :primary_key => :citizen_id,
            :class_name => "Ragnarok2::Translations::CitizenJobName"

    has_many :quest_citizens, :dependent => :destroy
    has_many :quests, :through => :quest_citizens

    has_many :start_quests,
            :through => :quest_citizens,
            :class_name => "Ragnarok2::Quest",
            :source => :quest,
            :conditions => ["ragnarok2_quest_citizens.is_start = ?", true]

    has_many :citizen_items, :dependent => :destroy
    has_many :sellitems,
            :through => :citizen_items,
            :class_name => "Ragnarok2::Item",
            :source => :item

    has_many :citizen_drops,
            :dependent => :destroy
    has_many :dropitems,
            :through => :citizen_drops,
            :class_name => "Ragnarok2::Item",
            :source => :item

    has_many :spawn_points,
        :primary_key => :citizen_id,
        :dependent => :destroy

    has_many :maps, :through => :spawn_points
            

    after_save :update_function_information

    alias_method :drops, :citizen_drops


    scope :default_order, order("ragnarok2_citizens.min_level ASC, ragnarok2_translations_citizen_names.translation ASC")

    scope :search_by_name, lambda {|q|
        joins{name.inner}.where{name.translation =~ "%#{q}%"}
    }

    search_for :name, :as => :string do |b, q|
        b.joins{name.inner}.where{name.translation =~ "%#{q}%"}
    end
    search_for :min_level, :as => :integer do |b, q|
        b.where{min_level.gteq q}
    end
    search_for :max_level, :as => :integer do |b, q|
        b.where{max_level.lteq q}
    end

    def items
        self.dropitems+self.sellitems
    end

    def to_s
      "#{self.name}"
    end

    def to_param
      "#{self.id}-#{self.name.to_s.parameterize}"
    end

    def resistances
        [
            [:water, self.water_resist],
            [:earth, self.earth_resist],
            [:fire, self.fire_resist],
            [:wind, self.wind_resist],
            [:poison, self.poison_resist],
            [:saint, self.saint_resist],
            [:dark, self.dark_resist],
            [:psychokinesis, self.psychokinesis_resist],
            [:death, self.death_resist],
        ].delete_if{|k,v| v.zero?}
    end

    def exp
        exp = BaseExp.where(:base_level=>[self.min_level, self.max_level])
        exp.collect{|e| e.npc_base_exp}
    end

    private
    def function_information_changed?
      1.upto(3) do |i|
        return true if self.send("function_id_#{1}_changed?") || self.send("function_type_#{1}_changed?")
      end
    end


    def update_function_information(force=false)
        return unless force || function_information_changed?

        #delete all function information
        self.citizen_items.destroy_all
        #readd all function information
        1.upto(3) do |i|
            case self.send("function_type_#{i}")
            when 11 #merchant
                entries = MerchantInfo.where(:merchant_function_id=>self.send("function_id_#{i}"))
                entries.each do |e|
                    item = Item.where(:item_id=>e.item_id).first
                    next unless item
                    self.citizen_items.create(
                        :item=>item, :max=>e.max,
                        :buy_type=>e.buy_type
                    )
                end
            end
        end
    end
  end
end
