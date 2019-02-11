Pod::Spec.new do |s|
	s.name    = 'AudioKit'
	s.version = '4.5.6'

	s.author      = 'Ufosek'
	s.homepage    = 'https://github.com/Ufosek/AudioKit'
	s.license     = { :type => 'MIT', :file => 'LICENSE' }
	s.platform    = :ios, '9.0'
	s.source      = { :git => 'https://github.com/Ufosek/AudioKit.git', :tag => s.version.to_s }
	s.summary     = 'No summary'
	s.source_files = 'AudioKit/*.swift'
end