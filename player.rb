class Player
  def initialize
    @hp_needed = 0
    @dirs = [:forward, :backward]
  end

  def shoot_at(unit)
    @dirs.each do |dir|
      @warrior.look(dir).take(3).each do |space|
        if space.unit.kind_of? unit
          @warrior.shoot! dir
          return true
        elsif !space.empty?
          break
        end
      end
    end
    nil
  end
  
  def shoot
    if can_shoot
      shoot_at(RubyWarrior::Units::Wizard) || shoot_at(RubyWarrior::Units::Archer)
    end
  end

  def can_shoot
    @warrior.respond_to? :shoot!
  end

  def scout
    puts "Before scout: #{@hp_needed}"
    @hp_needed = [@hp_needed, health_needed].max
    puts "After scout: #{@hp_needed}"
  end

  def play_turn(warrior)
    hp = warrior.health
    @maxhp ||= hp
    @lasthp = @hp || @maxhp
    @hp = hp
    @warrior = warrior

    if @fighting and !warrior.feel.enemy?
      # we just won a fight
      @hp_needed = 0
    end
    @fighting = false

    scout
    if warrior.feel.wall?
      warrior.pivot!
#    if not @captive_rescued
#      smart_move :backward
    elsif warrior.feel.enemy?
      warrior.attack!
      @fighting = true
    elsif shoot
      puts "shooting"
      @fighting = true
      # shoot has side effects
    elsif critical and being_attacked
      smart_move(:backward)
    elsif wounded and !being_attacked and @hp < @hp_needed
      warrior.rest!
    elsif warrior.feel.captive?
      warrior.rescue!
    else
      smart_move
    end
  end

  def smart_move(dir = :forward)
    space = @warrior.feel dir
    if space.wall?
      false
    else
      if space.empty?
        @warrior.walk! dir
      elsif space.enemy?
        @warrior.attack! dir
      elsif space.captive?
        @warrior.rescue! dir
        @captive_rescued = true
      end
      true
    end
  end

  def ranged
    lambda do |unit|
      unit.kind_of? RubyWarrior::Units::Wizard or unit.kind_of? RubyWarrior::Units::Archer
    end
  end

  def visible?(pred)
    @dirs.each do |dir|
      @warrior.look(dir).each do |space|
        u = space.unit
        if u && pred[u]
          return true
        elsif !space.empty?
          break;
        end
      end
    end
    nil
  end

  def being_attacked
    visible?(ranged) || @hp < @lasthp
  end

  def wounded
    @hp < @maxhp
  end

  def critical
    @hp < @maxhp / 3
  end

  def health_needed 
    damage = [:backward, :forward].map do |dir|
      @warrior.look(dir)
    end.flatten(1).map do |space|
      damage_budget(space.unit) || 0
    end.reduce :+ 
    damage + 1
  end

  def damage_budget(u) # how much will killing this hurt?
    {
      RubyWarrior::Units::Archer => can_shoot ? 6 : 9,
      RubyWarrior::Units::Sludge => 6,
      RubyWarrior::Units::ThickSludge => 12
    }[u.class]
  end
end
