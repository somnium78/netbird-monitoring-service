%define version %(cat VERSION 2>/dev/null || echo "1.1.0")

Name:           netbird-monitoring-service
Version:        %{version}
Release:        1%{?dist}
Summary:        NetBird Monitoring Service

License:        MIT
URL:            https://github.com/somnium78/netbird-monitoring-service
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
Requires:       systemd
Requires:       bash
Requires:       curl
BuildRequires:  systemd

%description
A systemd service and timer for monitoring NetBird VPN connections.

%prep
%setup -q

%build
# Nothing to build

%install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_unitdir}
mkdir -p %{buildroot}%{_sysconfdir}/netbird
mkdir -p %{buildroot}%{_sysconfdir}/logrotate.d
mkdir -p %{buildroot}%{_localstatedir}/log/netbird

install -m 755 src/netbird-monitor.sh %{buildroot}%{_bindir}/netbird-monitor.sh
install -m 644 src/netbird-monitor.service %{buildroot}%{_unitdir}/
install -m 644 src/netbird-monitor.timer %{buildroot}%{_unitdir}/
install -m 644 src/netbird-monitor.logrotate %{buildroot}%{_sysconfdir}/logrotate.d/netbird-monitor
install -m 644 src/netbird-monitor.conf.example %{buildroot}%{_sysconfdir}/netbird/monitor.conf

%post
%systemd_post netbird-monitor.timer
%systemd_post netbird-monitor.service

%preun
%systemd_preun netbird-monitor.timer
%systemd_preun netbird-monitor.service

%postun
%systemd_postun_with_restart netbird-monitor.timer
%systemd_postun_with_restart netbird-monitor.service

%files
%{_bindir}/netbird-monitor.sh
%{_unitdir}/netbird-monitor.service
%{_unitdir}/netbird-monitor.timer
%config(noreplace) %{_sysconfdir}/netbird/monitor.conf
%{_sysconfdir}/logrotate.d/netbird-monitor
%dir %{_localstatedir}/log/netbird

%changelog
* Mon Sep 02 2024 somnium78 <user@example.com> - 1.1.0-1
- Restructured repository with automated builds
- Updated from manual DEB package (1.0-3) to automated build system
- Added multi-platform support (Debian + RHEL/CentOS)
- GitHub Actions CI/CD integration
