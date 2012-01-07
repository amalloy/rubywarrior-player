class Player
  def shoot(dir = :forward)
    @warrior.look(dir).take(3).each do |space|
      if space.enemy?
        @warrior.shoot!(dir)
        return true
      elsif !space.empty?
        return false
      end
    end
    return false
  end

  def play_turn(warrior)
    hp = warrior.health
    @maxhp ||= hp
    @lasthp = @hp || @maxhp
    @hp = hp
    @warrior = warrior

    if warrior.feel.wall?
      warrior.pivot!
#    if not @captive_rescued
#      smart_move :backward
    elsif warrior.feel.enemy?
      warrior.attack!
    elsif shoot
      # shoot has side effects
    elsif critical and being_attacked
      warrior.walk!(:backward)
    elsif wounded and not being_attacked
      warrior.rest!
    elsif warrior.feel.captive?
      warrior.rescue!
    else
      warrior.walk!
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

  def being_attacked
    @hp < @lasthp
  end

  def wounded
    @hp < @maxhp
  end

  def critical
    @hp < @maxhp * 5 / 8
  end
end
