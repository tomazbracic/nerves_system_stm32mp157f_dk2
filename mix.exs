defmodule NervesSystemStm32mp157fDk2.MixProject do
  use Mix.Project

  @github_organization "tomazbracic"
  @app :nerves_system_stm32mp157f_dk2
  @version File.read!("VERSION") |> String.trim()

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.17",
      compilers: Mix.compilers() ++ [:nerves_package],
      nerves_package: nerves_package(),
      description: description(),
      package: package(),
      deps: deps(),
      aliases: [loadconfig: [&bootstrap/1]]
    ]
  end

  def application do
    []
  end

  defp bootstrap(args) do
    System.put_env("MIX_TARGET", "stm32mp157f_dk2")
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  defp nerves_package do
    [
      type: :system,
      artifact_sites: [
        {:github_releases, "#{@github_organization}/#{@app}"}
      ],
      platform: Nerves.System.BR,
      platform_config: [
        defconfig: "nerves_defconfig"
      ],
      env: [
        {"TARGET_ARCH", "arm"},
        {"TARGET_CPU", "cortex_a7"},
        {"TARGET_OS", "linux"},
        {"TARGET_ABI", "gnueabihf"}
      ],
      checksum: package_files()
    ]
  end

  defp deps do
    [
      {:nerves, "~> 1.10", runtime: false},
      {:nerves_system_br, "~> 1.28", runtime: false},
      {:nerves_toolchain_armv7_nerves_linux_gnueabihf, "~> 13.2.0", runtime: false}
    ]
  end

  defp description do
    "Nerves system for the STM32MP157F-DK2 Discovery Board"
  end

  defp package do
    [
      files: package_files(),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/#{@github_organization}/#{@app}"}
    ]
  end

  defp package_files do
    [
      "fwup.conf",
      "fwup-revert.conf",
      "fwup_include",
      "linux-6.6.defconfig",
      "mix.exs",
      "nerves_defconfig",
      "post-build.sh",
      "post-createfs.sh",
      "rootfs_overlay",
      "uboot",
      "VERSION"
    ]
  end
end
