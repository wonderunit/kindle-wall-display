#!/bin/sh
##
#
#  MR Package Installer
#
#  $Id: mrinstaller.sh 13359 2016-07-12 13:18:45Z NiLuJe $
#
##

# Remember our current revision for logging purposes...
MRPI_REV="$( echo '$Revision: 13359 $' | cut -d ' ' -f 2 )"

## Logging
# Pull some helper functions for logging
_FUNCTIONS=/etc/upstart/functions
if [ -f ${_FUNCTIONS} ] ; then
	source ${_FUNCTIONS}
else
	# legacy...
	_FUNCTIONS=/etc/rc.d/functions
	[ -f ${_FUNCTIONS} ] && source ${_FUNCTIONS}
fi

IS_K5="true"
# We need to get the proper constants for our model...
kmodel="$(cut -c3-4 /proc/usid)"
case "${kmodel}" in
	"13" | "54" | "2A" | "4F" | "52" | "53" )
		# Voyage...
		SCREEN_X_RES=1088
		SCREEN_Y_RES=1448
		EIPS_X_RES=16
		EIPS_Y_RES=24
	;;
	"24" | "1B" | "1D" | "1F" | "1C" | "20" | "D4" | "5A" | "D5" | "D6" | "D7" | "D8" | "F2" | "17" | "60" | "F4" | "F9" | "62" | "61" | "5F" )
		# PaperWhite...
		SCREEN_X_RES=768
		SCREEN_Y_RES=1024
		EIPS_X_RES=16
		EIPS_Y_RES=24
	;;
	"C6" | "DD" )
		# KT2...
		SCREEN_X_RES=608
		SCREEN_Y_RES=800
		EIPS_X_RES=16
		EIPS_Y_RES=24
	;;
	"0F" | "11" | "10" | "12" )
		# Touch
		SCREEN_X_RES=600
		SCREEN_Y_RES=800
		EIPS_X_RES=12
		EIPS_Y_RES=20
	;;
	* )
		# Handle legacy devices...
		if [ -f "/etc/rc.d/functions" ] && grep "EIPS" "/etc/rc.d/functions" > /dev/null 2>&1 ; then
			IS_K5="false"
			# And we've already sourced the proper values from there ;).
		else
			# Try the new device ID scheme...
			kmodel="$(cut -c4-6 /proc/usid)"
			case "${kmodel}" in
				"0G1" | "0G2" | "0G4" | "0G5" | "0G6" | "0G7" | "0KB" | "0KC" | "0KD" | "0KE" | "0KF" | "0KG" )
					# PW3... NOTE: Hopefully matches the KV...
					SCREEN_X_RES=1088
					SCREEN_Y_RES=1448
					EIPS_X_RES=16
					EIPS_Y_RES=24
				;;
				"0GC" | "0GD" | "0GR" | "0GS" | "0GT" | "0GU" )
					# Oasis... NOTE: Hopefully matches the KV...
					SCREEN_X_RES=1088
					SCREEN_Y_RES=1448
					EIPS_X_RES=16
					EIPS_Y_RES=24
				;;
				"0DU" | "0K9" | "0KA" )
					# KT3... NOTE: Hopefully matches the KT2...
					SCREEN_X_RES=608
					SCREEN_Y_RES=800
					EIPS_X_RES=16
					EIPS_Y_RES=24
				;;
				* )
					# Fallback... We shouldn't ever hit that.
					SCREEN_X_RES=600
					SCREEN_Y_RES=800
					EIPS_X_RES=12
					EIPS_Y_RES=20
					# NOTE: We still assume the device uses the new device ID scheme at this point.
				;;
			esac
		fi
	;;
esac
# And now we can do the maths ;)
EIPS_MAXCHARS="$((${SCREEN_X_RES} / ${EIPS_X_RES}))"
EIPS_MAXLINES="$((${SCREEN_Y_RES} / ${EIPS_Y_RES}))"

## Check if we're a K5
check_is_touch_device()
{
	[ "${IS_K5}" == "true" ] && return 0

	# We're not!
	return 1
}

# Logging...
logmsg()
{
	if check_is_touch_device ; then
		# Adapt the K5 logging calls to the simpler legacy syntax
		f_log "${1}" "mr_installer" "${2}" "${3}" "${4}"
	else
		# Slightly tweaked version of msg() (from ${_FUNCTIONS}, where the constants are defined)
		local _NVPAIRS
		local _FREETEXT
		local _MSG_SLLVL
		local _MSG_SLNUM

		_MSG_LEVEL="${1}"
		_MSG_COMP="${2}"

		{ [ $# -ge 4 ] && _NVPAIRS="${3}" && shift ; }

		_FREETEXT="${3}"

		eval _MSG_SLLVL=\${MSG_SLLVL_$_MSG_LEVEL}
		eval _MSG_SLNUM=\${MSG_SLNUM_$_MSG_LEVEL}

		local _CURLVL

		{ [ -f ${MSG_CUR_LVL} ] && _CURLVL=$(cat ${MSG_CUR_LVL}) ; } || _CURLVL=1

		if [ ${_MSG_SLNUM} -ge ${_CURLVL} ] ; then
			/usr/bin/logger -p local4.${_MSG_SLLVL} -t "mr_installer" "${_MSG_LEVEL} def:${_MSG_COMP}:${_NVPAIRS}:${_FREETEXT}"
		fi

		[ "${_MSG_LEVEL}" != "D" ] && echo "mr_installer: ${_MSG_LEVEL} def:${_MSG_COMP}:${_NVPAIRS}:${_FREETEXT}"
	fi
}

# Adapted from libkh[5]
eips_print_bottom_centered()
{
	# We need at least two args
	if [ $# -lt 2 ] ; then
		logmsg "W" "eips_print_bottom_centered" "" "not enough arguments passed to eips_print_bottom_centered ($# while we need at least 2)"
		return 1
	fi

	kh_eips_string="${1}"
	kh_eips_y_shift_up="${2}"

	# Log it, too
	logmsg "I" "eips_print_bottom_centered" "" "${kh_eips_string}"

	# Get the real string length now
	kh_eips_strlen="${#kh_eips_string}"

	# Add the right amount of left & right padding, since we're centered, and eips doesn't trigger a full refresh,
	# so we'll have to padd our string with blank spaces to make sure two consecutive messages don't run into each other
	kh_padlen="$(((${EIPS_MAXCHARS} - ${kh_eips_strlen}) / 2))"

	# Left padding...
	while [ ${#kh_eips_string} -lt $((${kh_eips_strlen} + ${kh_padlen})) ] ; do
		kh_eips_string=" ${kh_eips_string}"
	done

	# Right padding (crop to the edge of the screen)
	while [ ${#kh_eips_string} -lt ${EIPS_MAXCHARS} ] ; do
		kh_eips_string="${kh_eips_string} "
	done

	# Sleep a tiny bit to workaround the logic in the 'new' (K4+) eInk controllers that tries to bundle updates
	if [ "${EIPS_SLEEP}" == "true" ] ; then
		usleep 150000	# 150ms
	fi

	# And finally, show our formatted message centered on the bottom of the screen (NOTE: Redirect to /dev/null to kill unavailable character & pixel not in range warning messages)
	eips 0 $((${EIPS_MAXLINES} - 2 - ${kh_eips_y_shift_up})) "${kh_eips_string}" >/dev/null
}

## Check if arg is an int
is_integer()
{
	# Cheap trick ;)
	[ "${1}" -eq "${1}" ] 2>/dev/null
	return $?
}

## Compute our current OTA version (NOTE: Pilfered from Helper's device_id.sh ;))
compute_current_ota_version()
{
	fw_build_maj="$(awk '/Version:/ { print $NF }' /etc/version.txt | awk -F- '{ print $NF }')"
	fw_build_min="$(awk '/Version:/ { print $NF }' /etc/version.txt | awk -F- '{ print $1 }')"
	# Legacy major versions used to have a leading zero, which is stripped from the complete build number. Except on really ancient builds, that (or an extra) 0 is always used as a separator between maj and min...
	fw_build_maj_pp="${fw_build_maj#0}"
	# That only leaves some weird diags build that handle this stuff in potentially even weirder ways to take care of...
	if [ "${fw_build_maj}" -eq "${fw_build_min}" ] ; then
		# Weird diags builds... (5.0.0)
		fw_build="${fw_build_maj_pp}0???"
	else
		# Most common instance... maj#6 + 0 + min#3 or maj#5 + 0 + min#3 (potentially with a leading 0 stripped from maj#5)
		if [ ${#fw_build_min} -eq 3 ] ; then
			fw_build="${fw_build_maj_pp}0${fw_build_min}"
		else
			# Truly ancient builds... For instance, 2.5.6, which is maj#5 + min#4 (with a leading 0 stripped from maj#5)
			fw_build="${fw_build_maj_pp}${fw_build_min}"
		fi
	fi
}

## Call kindletool with the right environment setup
MRINSTALLER_BINDIR="$(dirname "$(realpath "${0}")")"
MRINSTALLER_BASEDIR="${MRINSTALLER_BINDIR%*/bin}"
run_kindletool()
{
	# Pick the right binary for our device...
	MACHINE_ARCH="$(uname -m)"
	if [ "${MACHINE_ARCH}" == "armv7l" ] ; then
		# FIXME: Slightly crappy Wario detection ;p
		if grep 'i.MX 6SoloLite' /proc/cpuinfo > /dev/null 2>&1 ; then
			BINARIES_TC="PW2"
		else
			BINARIES_TC="K5"
		fi
	else
		BINARIES_TC="K3"
	fi

	# Check if we have a tarball of binaries to install...
	if [ -f "${MRINSTALLER_BASEDIR}/data/mrpi-${BINARIES_TC}.tar.gz" ] ; then
		# Clear existing binaries...
		for tc_set in K3 K5 PW2 ; do
			for bin_set in lib bin ; do
				for file in ${MRINSTALLER_BASEDIR}/${bin_set}/${tc_set}/* ; do
					[ -f "${file}" ] && rm -f "${file}"
				done
			done
		done
		tar -xvzf "${MRINSTALLER_BASEDIR}/data/mrpi-${BINARIES_TC}.tar.gz" -C "${MRINSTALLER_BASEDIR}"
		# Clear data folder now
		for file in ${MRINSTALLER_BASEDIR}/data/mrpi-*.tar.gz ; do
			[ -f "${file}" ] && rm -f "${file}"
		done
	fi

	# Check that our binary actually is available...
	if [ ! -x "${MRINSTALLER_BASEDIR}/bin/${BINARIES_TC}/kindletool" ] ; then
		eips_print_bottom_centered "No KindleTool binary, aborting" 1
		echo -e "\nCould not find a proper KindleTool binary for the current arch (${BINARIES_TC}), aborting . . . :(\n" >> "${MRINSTALLER_BASEDIR}/log/mrinstaller.log"
		return 1
	fi

	# Pick up our own libz build...
	env KT_WITH_UNKNOWN_DEVCODES="true" LD_LIBRARY_PATH="${MRINSTALLER_BASEDIR}/lib/${BINARIES_TC}" ${MRINSTALLER_BASEDIR}/bin/${BINARIES_TC}/kindletool "$@"
}

## Check that we have enough free space
enough_free_space()
{
	if [ "$(df -k /mnt/us | awk '$3 ~ /[0-9]+/ { print $4 }')" -lt "$((100 * 1024))" ] ; then
		# Less than 100MB left, meep!
		return 1
	else
		# Good enough!
		return 0
	fi
}

## Reimplement mntroot ourselves, because its checks aren't as robust as one would hope...
is_rootfs_ro()
{
	if awk '$4~/(^|,)ro($|,)/' /proc/mounts | grep '^/dev/root / ' >/dev/null 2>&1 ; then
		# Peachy :)
		return 0
	fi

	# Hu oh, it's rw...
	return 1
}

is_rootfs_rw()
{
	if awk '$4~/(^|,)rw($|,)/' /proc/mounts | grep '^/dev/root / ' >/dev/null 2>&1 ; then
		# Peachy :)
		return 0
	fi

	# Hu oh, it's ro...
	return 1
}

make_rootfs_rw()
{
	logmsg "I" "make_rootfs_rw" "" "trying to remount rootfs rw"

	# Sync first...
	sync

	# Don't do anything if for some strange reason it's already rw...
	if is_rootfs_rw ; then
		logmsg "W" "make_rootfs_rw" "" "rootfs is already rw!"
		return 0
	fi

	# Do eet!
	/bin/mount -o remount,rw /
	if [ $? -ne 0 ] ; then
		logmsg "E" "make_rootfs_rw" "" "failed to remount rootfs rw!"
		return 1
	fi

	# Even if it appeared to work, double check...
	if is_rootfs_ro ; then
		logmsg "E" "make_rootfs_rw" "" "rootfs is still ro after a rw remount!"
		return 1
	fi

	# Success!
	logmsg "I" "make_rootfs_rw" "" "rootfs has been remounted rw"
	return 0
}

make_rootfs_ro()
{
	logmsg "I" "make_rootfs_ro" "" "trying to remount rootfs ro"

	# Sync first...
	sync

	# Don't do anything if for some strange reason it's already ro...
	if is_rootfs_ro ; then
		logmsg "W" "make_rootfs_ro" "" "rootfs is already ro!"
		return 0
	fi

	# Do eet!
	/bin/mount -o remount,ro /
	if [ $? -ne 0 ] ; then
		logmsg "E" "make_rootfs_ro" "" "failed to remount rootfs ro!"
		return 1
	fi

	# Even if it appeared to work, double check...
	if is_rootfs_rw ; then
		logmsg "E" "make_rootfs_ro" "" "rootfs is still rw after a ro remount!"
		return 1
	fi

	# Success!
	logmsg "I" "make_rootfs_ro" "" "rootfs has been remounted ro"
	return 0
}

# Our packages live in a specific directory
MRPI_PKGDIR="/mnt/us/mrpackages"
# We're working in a staging directory
MRPI_WORKDIR="${MRPI_PKGDIR}/staging"
## Run a single package
run_package()
{
	# We need at one arg
	if [ $# -lt 1 ] ; then
		logmsg "W" "run_package" "" "not enough arguments passed to run_package ($# while we need at least 1)"
		return 1
	fi

	# Clear our five lines...
	eips_print_bottom_centered "" 4
	eips_print_bottom_centered "" 3
	eips_print_bottom_centered "" 2
	eips_print_bottom_centered "" 1
	eips_print_bottom_centered "" 0

	PKG_FILENAME="${1}"

	# Cleanup the name a bit for the screen
	PKG_NAME="${PKG_FILENAME#[uU]pdate[-_]*}"
	# Legacy devices have an older busybox version, with an ash build that sucks even more! [Can't use / substitutions]
	PKG_NAME="$(echo ${PKG_NAME} | sed -e 's/uninstall/U/')"
	PKG_NAME="$(echo ${PKG_NAME} | sed -e 's/install/I/')"
	PKG_NAME="$(echo ${PKG_NAME} | sed -e 's/touch_pw/K5/')"
	PKG_NAME="$(echo ${PKG_NAME} | sed -e 's/pw2_kt2_kv_pw3_koa_kt3/WARIO+/')"
	PKG_NAME="$(echo ${PKG_NAME} | sed -e 's/pw2_kt2_kv_pw3/WARIO/')"
	PKG_NAME="$(echo ${PKG_NAME} | sed -e 's/pw2_kt2_kv/WARIO/')"
	PKG_NAME="$(echo ${PKG_NAME} | sed -e 's/pw2/PW2/')"
	PKG_NAME="$(echo ${PKG_NAME} | sed -e 's/k2_dx_k3/LEGACY/')"
	PKG_NAME="${PKG_NAME%*.bin}"
	PKG_NAME="$(echo ${PKG_NAME} | sed -e 's/[-_]/ /g')"

	# Start by timestamping our logs...
	echo -e "\n\n**** **** **** ****" >> "${MRINSTALLER_BASEDIR}/log/mrinstaller.log"
	echo -e "\n[$(date +'%F @ %T %z')] :: [MRPI r${MRPI_REV}] - Beginning the processing of package '${PKG_FILENAME}' (${PKG_NAME}) . . .\n" >> "${MRINSTALLER_BASEDIR}/log/mrinstaller.log"

	# Check if it's valid...
	eips_print_bottom_centered "Checking ${PKG_NAME}" 4
	# Always re-compute the OTA number, in case something dared to mess with it...
	compute_current_ota_version
	# Save KindleTool's output (Tweak the IFS to make our life easier...)
	BASE_IFS="${IFS}"
	IFS=''
	ktool_output="$(run_kindletool convert -i "${PKG_FILENAME}" 2>&1)"
	# On the off chance that failed, abort
	if [ $? -ne 0 ] ; then
		eips_print_bottom_centered "Failed to parse package, skipping" 1
		echo -e "\nFailed to parse package '${PKG_FILENAME}' (${PKG_NAME}), skipping . . . :(\n" >> "${MRINSTALLER_BASEDIR}/log/mrinstaller.log"
		IFS="${BASE_IFS}"
		return 1
	fi
	# Check bundle type
	PKG_BUNDLE_TYPE="$(echo ${ktool_output} | sed -n -r 's/^(Bundle Type)([[:blank:]]*)(.*?)$/\3/p')"
	case "${PKG_BUNDLE_TYPE}" in
		"OTA V1" )
			PKG_PADDING_BYTE="$(echo ${ktool_output} | sed -n -r 's/^(Padding Byte)([[:blank:]]*)([[:digit:]]*)( \()(.*?)(\))$/\5/p')"
			PKG_DEVICE_CODE="$(echo ${ktool_output} | sed -n -r '/^(Device)([[:blank:]]*)(.*?)$/p' | sed -n -r -e 's/^(Device)([[:blank:]]*)(.*?)(\()//' -e 's/((([[:xdigit:]G-V]{3})( -> 0x)([[:xdigit:]]{3}))|((0x)([[:xdigit:]]{2})))(\))(.*?)$/\3\8/p')"
			PKG_MIN_OTA="$(echo ${ktool_output} | sed -n -r 's/^(Minimum OTA)([[:blank:]]*)([[:digit:]]*)$/\3/p')"
			PKG_MAX_OTA="$(echo ${ktool_output} | sed -n -r 's/^(Target OTA)([[:blank:]]*)([[:digit:]]*)$/\3/p')"
			# Now that we're done with KindleTool's output, restore our original IFS value...
			IFS="${BASE_IFS}"

			# Check padding byte
			case "${PKG_PADDING_BYTE}" in
				"0x13" | "0x00" )
					is_mr_package="true"
				;;
				* )
					is_mr_package="false"
				;;
			esac
			# Reject non-MR packages
			if [ "${is_mr_package}" == "false" ] ; then
				eips_print_bottom_centered "Not an MR package, skipping" 1
				echo -e "\nPackage '${PKG_FILENAME}' (${PKG_NAME}) is not an MR package, skipping . . . :(\n" >> "${MRINSTALLER_BASEDIR}/log/mrinstaller.log"
				return 1
			fi

			# Check device code
			if [ "${kmodel}" != "${PKG_DEVICE_CODE}" ] ; then
				eips_print_bottom_centered "Not targeting your device, skipping" 1
				echo -e "\nPackage '${PKG_FILENAME}' (${PKG_NAME}) is not targeting your device [${kmodel} vs. ${PKG_DEVICE_CODE}], skipping . . . :(\n" >> "${MRINSTALLER_BASEDIR}/log/mrinstaller.log"
				return 1
			fi

			# Version check... NOTE: Busybox (and Bash < 3) stores ints as int_32_t (i.e., signed 32bit), so we have to get creative to avoid overflows... >_<. We don't have access to bc, so rely on awk...
			if [ "$(awk -v fw_build="${fw_build}" -v PKG_MIN_OTA="${PKG_MIN_OTA}" -v PKG_MAX_OTA="${PKG_MAX_OTA}" 'BEGIN { print (fw_build < PKG_MIN_OTA || fw_build > PKG_MAX_OTA) }')" -ne 0 ] ; then
				eips_print_bottom_centered "Not targeting your FW version, skipping" 1
				echo -e "\nPackage '${PKG_FILENAME}' (${PKG_NAME}) is not targeting your FW version [!(${PKG_MIN_OTA} < ${fw_build} < ${PKG_MAX_OTA})], skipping . . . :(\n" >> "${MRINSTALLER_BASEDIR}/log/mrinstaller.log"
				return 1
			fi
		;;
		"OTA V2" )
			PKG_CERT_NUM="$(echo ${ktool_output} | sed -n -r 's/^(Cert number)([[:blank:]]*)(.*?)$/\3/p')"
			PKG_DEVICES_CODES="$(echo ${ktool_output} | sed -n -r '/^(Device)([[:blank:]]*)(.*?)$/p' | sed -n -r -e 's/^(Device)([[:blank:]]*)(.*?)(\()//' -e 's/((([[:xdigit:]G-V]{3})( -> 0x)([[:xdigit:]]{3}))|((0x)([[:xdigit:]]{2})))(\))(.*?)$/\3\8/p')"
			PKG_MIN_OTA="$(echo ${ktool_output} | sed -n -r 's/^(Minimum OTA)([[:blank:]]*)([[:digit:]]*)$/\3/p')"
			PKG_MAX_OTA="$(echo ${ktool_output} | sed -n -r 's/^(Target OTA)([[:blank:]]*)([[:digit:]]*)$/\3/p')"
			# Now that we're done with KindleTool's output, restore our original IFS value...
			IFS="${BASE_IFS}"

			# Check signing cert to reject non-MR packages
			if [ "${PKG_CERT_NUM}" -ne 0 ] ; then
				eips_print_bottom_centered "Not an MR package, skipping" 1
				echo -e "\nPackage '${PKG_FILENAME}' (${PKG_NAME}) is not an MR package, skipping . . . :(\n" >> "${MRINSTALLER_BASEDIR}/log/mrinstaller.log"
				return 1
			fi

			# Check device codes
			devcode_match="false"
			for cur_devcode in ${PKG_DEVICES_CODES} ; do
				if [ "${kmodel}" == "${cur_devcode}" ] ; then
					devcode_match="true"
				fi
			done
			if [ "${devcode_match}" == "false" ] ; then
				eips_print_bottom_centered "Not targeting your device, skipping" 1
				echo -e "\nPackage '${PKG_FILENAME}' (${PKG_NAME}) is not targeting your device [${kmodel} vs. $(echo ${PKG_DEVICES_CODES} | tr -s '\\n' ' ')], skipping . . . :(\n" >> "${MRINSTALLER_BASEDIR}/log/mrinstaller.log"
				return 1
			fi

			# Version check... NOTE: Busybox (and Bash < 3) stores ints as int_32_t, so we have to get creative to avoid overflows... >_<. We don't have access to bc, so rely on awk...
			if [ "$(awk -v fw_build="${fw_build}" -v PKG_MIN_OTA="${PKG_MIN_OTA}" -v PKG_MAX_OTA="${PKG_MAX_OTA}" 'BEGIN { print (fw_build < PKG_MIN_OTA || fw_build > PKG_MAX_OTA) }')" -ne 0 ] ; then
				eips_print_bottom_centered "Not targeting your FW version, skipping" 1
				echo -e "\nPackage '${PKG_FILENAME}' (${PKG_NAME}) is not targeting your FW version [!(${PKG_MIN_OTA} < ${fw_build} < ${PKG_MAX_OTA})] skipping . . . :(\n" >> "${MRINSTALLER_BASEDIR}/log/mrinstaller.log"
				return 1
			fi
		;;
		* )
			IFS="${BASE_IFS}"

			eips_print_bottom_centered "Not an OTA package, skipping" 1
			echo -e "\nPackage '${PKG_FILENAME}' (${PKG_NAME}) is not an OTA package [${PKG_BUNDLE_TYPE}], skipping . . . :(\n" >> "${MRINSTALLER_BASEDIR}/log/mrinstaller.log"
			return 1
		;;
	esac

	# Start it up...
	eips_print_bottom_centered "* ${PKG_NAME} *" 4

	# Clear workdir, and extract package in it
	rm -rf "${MRPI_WORKDIR}"
	if ! enough_free_space ; then
		eips_print_bottom_centered "Not enough free space left, skipping" 1
		echo -e "\nNot enough space left to process ${PKG_NAME}, skipping . . . :(\n" >> "${MRINSTALLER_BASEDIR}/log/mrinstaller.log"
		return 1
	fi
	run_kindletool extract "${PKG_FILENAME}" "${MRPI_WORKDIR}"
	# KindleTool handles the integrity checking for us, so let's check that this went fine...
	if [ $? -ne 0 ] ; then
		eips_print_bottom_centered "Failed to extract package, skipping" 1
		echo -e "\nFailed to extract package '${PKG_FILENAME}' (${PKG_NAME}), skipping . . . :(\n" >> "${MRINSTALLER_BASEDIR}/log/mrinstaller.log"
		return 1
	fi
	# We can then remove the package itself
	rm -f "${PKG_FILENAME}"

	# Make the rootfs rw...
	if ! make_rootfs_rw ; then
		eips_print_bottom_centered "Failed to remount rootfs RW, skipping" 1
		echo -e "\nFailed to remount rootfs RW, skipping ${PKG_NAME} . . . :(\n" >> "${MRINSTALLER_BASEDIR}/log/mrinstaller.log"
		sleep 5
		return 1
	fi

	# Run the package scripts in alphabetical order, from inside our workdir...
	cd "${MRPI_WORKDIR}"
	RAN_SOMETHING="false"
	# NOTE: We only handle toplevel scripts
	for pkg_script in *.sh *.ffs ; do
		if [ -f "./${pkg_script}" ] ; then
			RAN_SOMETHING="true"
			eips_print_bottom_centered "Running ${pkg_script} . . ." 3
			# Log what the script does...
			echo -e "--\nRunning '${pkg_script}' for '${PKG_NAME}' (${PKG_FILENAME}) @ $(date -R)\n" >> "${MRINSTALLER_BASEDIR}/log/mrinstaller.log"
			# Abort at the first sign of trouble...
			if check_is_touch_device ; then
				/bin/sh -e "./${pkg_script}" >> "${MRINSTALLER_BASEDIR}/log/mrinstaller.log" 2>&1
				# Catch errors...
				mrpi_ret="$?"
			else
				# NOTE: Unfortunately, on legacy devices, actually sourcing /etc/rc.d/functions will fail, so we can't use -e here... >_<"
				/bin/sh "./${pkg_script}" >> "${MRINSTALLER_BASEDIR}/log/mrinstaller.log" 2>&1
				# On the off-chance it'd actually be useful then, keep catching errors...
				mrpi_ret="$?"
			fi
			if [ ${mrpi_ret} -ne 0 ] ; then
				eips_print_bottom_centered "Package script failed (${mrpi_ret}), moving on . . . :(" 1
				echo -e "\nHu oh... Got return code ${mrpi_ret} . . . :(\n" >> "${MRINSTALLER_BASEDIR}/log/mrinstaller.log"
				# Leave time to the user to read it...
				sleep 10
			else
				eips_print_bottom_centered "Success. :)" 1
				echo -e "\nSuccess! :)\n" >> "${MRINSTALLER_BASEDIR}/log/mrinstaller.log"
			fi
		fi
	done
	# Warn if no scripts were found
	if [ "${RAN_SOMETHING}" == "false" ] ; then
		eips_print_bottom_centered "No scripts were found, skipping" 1
		echo -e "\nNo scripts were found, skipping . . . :(\n" >> "${MRINSTALLER_BASEDIR}/log/mrinstaller.log"
		sleep 5
	fi
	# And get out of the staging directory once we're done.
	cd "${MRPI_PKGDIR}"

	# Lock the rootfs down
	if ! make_rootfs_ro ; then
		eips_print_bottom_centered "Failed to remount rootfs RO -_-" 1
		echo -e "\nFailed to remount rootfs RO -_-\n" >> "${MRINSTALLER_BASEDIR}/log/mrinstaller.log"
		sleep 5
	fi

	# Clean up behind us
	rm -rf "${MRPI_WORKDIR}"

	return 0
}

## Go!
launch_installer()
{
	# Sleep a while to let KUAL die
	eips_print_bottom_centered "Hush, little baby . . ." 1
	sleep 5

	# NOTE: Fugly FW 5.6.1 handling. Die *before* stopping the UI if we're not root, because we might not be able to bring it back up otherwise.
	if [ "$(id -u)" -ne 0 ] ; then
		eips_print_bottom_centered "Unprivileged user, aborting." 1
		return 1
	fi

	# Let's do this!
	eips_print_bottom_centered "Launching the MR installer . . ." 1

	# Move to our package directory...
	mkdir -p "${MRPI_PKGDIR}"
	cd "${MRPI_PKGDIR}"

	# Loop over packages...
	for pkg in *.bin ; do
		# Check that we actually have some
		if [ -f "${pkg}" ] ; then
			# Try to build a list of packages, while honoring a modicum of dependency tree
			case "${pkg}" in
				*usbnet*install* )
					# Top priority
					MR_PKGS_HEAD_LIST="${pkg} ${MR_PKGS_HEAD_LIST}"
				;;
				*jailbreak*install* )
					# High priority
					MR_PKGS_HEAD_LIST="${MR_PKGS_HEAD_LIST} ${pkg}"
				;;
				*mkk*install* )
					# High priority
					MR_PKGS_HEAD_LIST="${MR_PKGS_HEAD_LIST} ${pkg}"
				;;
				*python*install* )
					# High priority
					MR_PKGS_HEAD_LIST="${MR_PKGS_HEAD_LIST} ${pkg}"
				;;
				*_rp_*install* | *_rescue_pack* )
					# High priority
					MR_PKGS_HEAD_LIST="${MR_PKGS_HEAD_LIST} ${pkg}"
				;;
				*jailbreak*uninstall* )
					# Lowest priority
					MR_PKGS_TAIL_LIST="${MR_PKGS_TAIL_LIST} ${pkg}"
				;;
				* )
					# Normal priority
					MR_PKGS_LIST="${MR_PKGS_LIST} ${pkg}"
				;;
			esac
		else
			# No packages were found, go away
			eips_print_bottom_centered "No MR packages found" 1
			return 1
		fi
	done

	# Construct our final package list
	MR_PKGS_LIST="${MR_PKGS_HEAD_LIST} ${MR_PKGS_LIST} ${MR_PKGS_TAIL_LIST}"

	# Don't get killed!
	trap "" SIGTERM

	# Bring down most of the services
	if check_is_touch_device ; then
		stop x
		# Let's settle down a bit...
		sleep 5
		# If AcXE is installed, stop it (it doesn't depend on the UI, and thus would still be up)
		if [ -f "/etc/upstart/acxe.conf" ] ; then
			# Check if it's up...
			if [ "$(status acxe)" == "acxe start/running" ] ; then
				stop acxe
				# Shouldn't happen...
				if [ $? -ne 0 ] ; then
					eips_print_bottom_centered "Failed to stop AcXE -_-" 1
					sleep 2
				fi
			fi
		fi
	else
		# This is going to get ugly... Clear the screen
		eips -c
		# If we're in USBNet mode, down it manually first, because we might need volumd to tear it down, which we won't have in single-user mode...
		# See the comments in USBNetwork itself related to volumd for the details on why we can't really keep it up during an update (TL;DR: it breaks usbms exports)...
		# NOTE: We need these shenanigans with custom services because we usually don't install the proper symlinks for the single-user runlevel... ;).
		if [ -f "/etc/init.d/usbnet" ] ; then
			# Do this unconditionally, the script is smart enough to figure out the rest ;).
			/etc/init.d/usbnet stop
		fi
		# Switch to single-user
		telinit 1
		# Reprint our message after the clear...
		sleep 2
		eips_print_bottom_centered "Launching the MR installer . . ." 1
		# Wait for everything to go down...
		sleep 20
		# Re-up syslog
		/etc/init.d/syslog-ng start

		# And down most of the custom stuff...
		# Start by listing everything that goes down when updating...
		for service in /etc/rc3.d/K* ; do
			UPDATE_RUNLEVEL_KILLS="${UPDATE_RUNLEVEL_KILLS} ${service##*/}"
		done
		# And everything that goes down in single-user mode...
		for service in /etc/rc1.d/K* ; do
			SINGLEU_RUNLEVEL_KILLS="${SINGLEU_RUNLEVEL_KILLS} ${service##*/}"
		done
		# Manually down anything that the updater runlevel downs, but not single-user...
		for cur_service in ${UPDATE_RUNLEVEL_KILLS} ; do
			is_custom="true"
			for service in ${SINGLEU_RUNLEVEL_KILLS} ; do
				if [ "${cur_service}" == "${service}" ] ; then
					is_custom="false"
				fi
			done
			# Is it *really* custom?
			if [ "${is_custom}" == "true" ] ; then
				# Don't store USBNet, we're handling it manually
				if [ "$(echo ${cur_service} | tail -c +4)" != "usbnet" ] ; then
					# Store the list of custom services without their order prefix...
					CUSTOM_SERVICES_LIST="${CUSTOM_SERVICES_LIST} $(echo ${cur_service} | tail -c +4)"
				fi
			fi
		done

		# And down them!
		for service in ${CUSTOM_SERVICES_LIST} ; do
			if [ -f "/etc/init.d/${service}" ] ; then
				/etc/init.d/${service} stop
			fi
		done

		# let's wait a bit more...
		sleep 7
	fi

	# Sync FS
	sync

	# And install our packages in order, one by one...
	for cur_pkg in ${MR_PKGS_LIST} ; do
		if [ -f "${cur_pkg}" ] ; then
			run_package "${cur_pkg}"
			# Remove package in case of failure...
			if [ $? -ne 0 ] ; then
				eips_print_bottom_centered "Destroying package . . ." 1
				rm -f "${cur_pkg}"
				# Don't leave a staging directory behind us, we might have failed without clearing it...
				rm -rf "${MRPI_WORKDIR}"
				# Try to avoid leaving a rw rootfs, we might have failed with it still rw...
				if ! make_rootfs_ro ; then
					eips_print_bottom_centered "Failed to remount rootfs RO -_-" 1
					sleep 5
				fi
				sleep 2
			fi
		else
			# Should never happen...
			eips_print_bottom_centered "${cur_pkg} is not a file, skipping" 1
		fi
	done

	# Sync FS
	sync

	# We're done! Enable sleepy eips calls in order to avoid losing our last message...
	EIPS_SLEEP="true"
	eips_print_bottom_centered "" 4
	eips_print_bottom_centered "" 3
	eips_print_bottom_centered "" 2
	eips_print_bottom_centered "Done, restarting UI . . ." 1
	eips_print_bottom_centered "" 0
	sleep 2

	# Bring the UI back up!
	if check_is_touch_device ; then
		# If we still have AcXE installed, restart it
		if [ -f "/etc/upstart/acxe.conf" ] ; then
			# Check if it's down...
			if [ "$(status acxe)" == "acxe stop/waiting" ] ; then
				start acxe
				# Shouldn't happen...
				if [ $? -ne 0 ] ; then
					eips_print_bottom_centered "Failed to start AcXE -_-" 1
					sleep 2
				else
					sleep 1
				fi
			fi
		fi
		start x
	else
		# Thankfully enough, we don't have to jump through any hoops this time ;).
		telinit 5
	fi
}

# Main
case "${1}" in
	"launch_installer" )
		${1}
	;;
	* )
		eips_print_bottom_centered "invalid action" 1
	;;
esac

return 0
