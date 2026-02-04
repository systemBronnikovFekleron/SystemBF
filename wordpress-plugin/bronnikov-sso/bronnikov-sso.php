<?php
/**
 * Plugin Name: Bronnikov SSO
 * Plugin URI: https://platform.bronnikov.com
 * Description: Single Sign-On интеграция с платформой "Система Бронникова"
 * Version: 1.0.0
 * Author: Bronnikov Team
 * Author URI: https://bronnikov.com
 * License: GPL v2 or later
 * License URI: https://www.gnu.org/licenses/gpl-2.0.html
 * Text Domain: bronnikov-sso
 * Domain Path: /languages
 *
 * @package BronnikovSSO
 */

// Exit if accessed directly.
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

// Define plugin constants.
define( 'BRONNIKOV_SSO_VERSION', '1.0.0' );
define( 'BRONNIKOV_SSO_PLUGIN_DIR', plugin_dir_path( __FILE__ ) );
define( 'BRONNIKOV_SSO_PLUGIN_URL', plugin_dir_url( __FILE__ ) );

// Require plugin files.
require_once BRONNIKOV_SSO_PLUGIN_DIR . 'includes/class-api.php';
require_once BRONNIKOV_SSO_PLUGIN_DIR . 'includes/class-auth.php';
require_once BRONNIKOV_SSO_PLUGIN_DIR . 'includes/class-user-sync.php';

// Admin files (only load in admin).
if ( is_admin() ) {
    require_once BRONNIKOV_SSO_PLUGIN_DIR . 'admin/class-settings.php';
}

/**
 * Initialize the plugin
 */
function bronnikov_sso_init() {
    // Auto-login on page load if JWT token exists
    add_action( 'init', array( 'Bronnikov_Auth', 'auto_login' ), 1 );

    // Sync user data after login
    add_action( 'wp_login', array( 'Bronnikov_User_Sync', 'sync_on_login' ), 10, 2 );
}
add_action( 'plugins_loaded', 'bronnikov_sso_init' );

/**
 * Plugin activation hook
 */
function bronnikov_sso_activate() {
    // Set default options
    if ( ! get_option( 'bronnikov_sso_settings' ) ) {
        add_option( 'bronnikov_sso_settings', array(
            'api_url' => 'https://platform.bronnikov.com',
            'enabled' => false,
        ) );
    }
}
register_activation_hook( __FILE__, 'bronnikov_sso_activate' );

/**
 * Plugin deactivation hook
 */
function bronnikov_sso_deactivate() {
    // Cleanup if needed
}
register_deactivation_hook( __FILE__, 'bronnikov_sso_deactivate' );
