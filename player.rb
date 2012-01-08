class Player
  def initialize
    @hp_needed = 0
    @keep_shooting = 0
    @dirs = [:forward, :backward]
  end

  def keep_shooting
    if @keep_shooting > 0
      @warrior.shoot! @shoot_dir
      @keep_shooting -= 1
      true
    end
  end

  def shoot_at(unit)
    @dirs.each do |dir|
      @warrior.look(dir).take(3).each_with_index do |space, i|
        u = space.unit
        if archer[u] and i < 2
          break # archers should be charged at if closer
        elsif u.kind_of? unit
          @warrior.shoot! dir
          @keep_shooting = arrow_budget(space.unit) - 1
          @shoot_dir = dir
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
    @hp_needed = [@hp_needed, health_needed].max
    puts "HP: #{@hp}, need: #{@hp_needed}"
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
    elsif warrior.feel.enemy?
      warrior.attack!
      @fighting = true
    elsif keep_shooting
      puts "Still shooting"
      @fighting = true
      # I guess we're shooting at him
    elsif critical and being_attacked
      puts "Retreat!"
      smart_move(:backward)
    elsif shoot
      puts "Start shooting"
      @fighting = true
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

  def archer
    lambda do |unit|
      unit.kind_of? RubyWarrior::Units::Archer
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
    visible?(archer) || @hp < @lasthp
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

  def arrow_budget(u) # how many times do I shoot at this?
    {
      RubyWarrior::Units::Archer => 3,
      RubyWarrior::Units::Wizard => 1
    }[u.class]
  end
end
