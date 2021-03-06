def bundler_10_installer(version, options = '')
  opts = [
    "--deployment",
    "--path #{c.shared_path}/bundled_gems",
    "--binstubs #{c.binstubs_path}",
    "--without development test cool_toys"
  ]
  BundleInstaller.new(version, opts.join(" ") + options)
end

class ::EY::Serverside::Deploy::Configuration
  def bundle_without
    "development test cool_toys"
  end
end

