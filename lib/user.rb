class User
  def self.members
    [
      OpenStruct.new(first_name: 'Ben', url: 'https://api.freeagent.com/v2/users/580257'),
      OpenStruct.new(first_name: 'Chris L', url: 'https://api.freeagent.com/v2/users/485461'),
      OpenStruct.new(first_name: 'Chris R', url: 'https://api.freeagent.com/v2/users/32469'),
      OpenStruct.new(first_name: 'James', url: 'https://api.freeagent.com/v2/users/7474'),
    ]
  end
end
