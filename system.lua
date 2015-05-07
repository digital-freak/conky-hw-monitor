require ('sysctl')

function conky_cpu_temperature(core)
	temperature = sysctl.IK2celsius(sysctl.get('dev.cpu.' .. core .. '.temperature')) .. ' ℃'

	return (temperature)
end

