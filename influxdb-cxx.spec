%global sname influxdb-cxx

Summary:	InfluxDB C++ client library
Name:		%{sname}
Version:	%{influxdbcxx_release_version}
Release:	%{?dist}
License:	MIT
Source0:	influxdb-cxx.tar.bz2
URL:		https://github.com/pgspider/influxdb-cxx
BuildRequires:	libcurl-devel openssl-devel cmake

%description
This is InfluxDB C++ client library for Rocky Linux8

%prep
%setup -q -n influxdb-cxx-%{version}

%{__cmake} -DINFLUXCXX_WITH_BOOST=OFF -DINFLUXCXX_TESTING=OFF .

%build
%{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}
%{__make} %{?_smp_mflags} install DESTDIR=%{buildroot}


%{__install} -d %{buildroot}/usr/local/include
%{__install} -d %{buildroot}/usr/local/lib64

%clean
%{__rm} -rf %{buildroot}

%post 
echo '/usr/local/lib64' > /etc/ld.so.conf.d/influxdb-cxx.conf
/sbin/ldconfig

%postun 
%{__rm} -f /etc/ld.so.conf.d/influxdb-cxx.conf
/sbin/ldconfig

%files
%defattr(755,root,root,755)
/usr/local/include/*
/usr/local/lib64/*
/usr/local/lib64/cmake/InfluxDB/*

%changelog
* Wed Nov 8 2023 - 0.0.1
- Init spec
