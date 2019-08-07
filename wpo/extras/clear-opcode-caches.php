<?php
/**
 * Plugin Name: Clear PHP opcode caches
 * Plugin URI: https://www.saotn.org/wordpress-plugin-flush-php-opcache/
 * Donate Link: https://www.paypal.me/jreilink
 * Description: Clears out various PHP opcode and user caches. Currently it tries to clear, or flush, PHP OPcache and WinCache caches from memory. Easily extended to flush Redis, Memcached, and APCu cache. This should ease WordPress updates and plugin activation / deactivation.
 * Network: True
 * Version: 1.0
 * Author: Jan Reilink
 * Author URI: https://www.saotn.org
 * License: GPLv2
 */

function clear_php_opcache() {
	if( ! extension_loaded( 'Zend OPcache' ) ) {
		return;
	}
	$opcache_status = opcache_get_status();
	if( false === $opcache_status["opcache_enabled"] ) {
		// extension loaded but OPcache not enabled
		return;
	}
	if( ! opcache_reset() ) { 
		return false;
	}
	else {
		/**
		 * opcache_reset() is performed, now try to clear the 
		 * file cache.
		 * Please note: http://stackoverflow.com/a/23587079/1297898
		 *   "Opcache does not evict invalid items from memory - they 
		 *   stay there until the pool is full at which point the 
		 *   memory is completely cleared"
		 */
		foreach( $opcache_status['scripts'] as $key => $data ) {
			$dirs[dirname( $key )][basename( $key )] = $data;
			opcache_invalidate( $data['full_path'] , $force = true );
		}
		return true;
	}
}

function clear_caches() {
	if( clear_php_opcache() ) {
		error_log( 'PHP OPcache opcode cache cleared.' );
	}
	else {
		error_log( 'Clearing PHP OPcache opcode cache failed.' );
	}
}

add_filter( 'plugin_row_meta', 'saotn1_plugin_row_meta', 10, 2 );
function saotn1_plugin_row_meta( $links, $file ) {
	if ( !preg_match('/clear-opcode-caches.php$/', $file ) ) {
	  return $links;
	}
		
	$links[] = sprintf(
	  '<a href="https://www.paypal.me/jreilink">%s</a>',
	  __( 'Donate' )
	);
	return $links;
}
add_filter( 'upgrader_pre_install', 'clear_caches', 10, 2 );
?>
