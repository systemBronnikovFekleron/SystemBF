<?php
/**
 * Admin settings page
 *
 * @package BronnikovSSO
 */

// Exit if accessed directly.
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * Class Bronnikov_Settings
 */
class Bronnikov_Settings {

    /**
     * Constructor
     */
    public function __construct() {
        add_action( 'admin_menu', array( $this, 'add_settings_page' ) );
        add_action( 'admin_init', array( $this, 'register_settings' ) );
        add_action( 'admin_enqueue_scripts', array( $this, 'enqueue_admin_styles' ) );
    }

    /**
     * Add settings page to admin menu
     */
    public function add_settings_page() {
        add_options_page(
            __( 'Bronnikov SSO Settings', 'bronnikov-sso' ),
            __( 'Bronnikov SSO', 'bronnikov-sso' ),
            'manage_options',
            'bronnikov-sso',
            array( $this, 'render_settings_page' )
        );
    }

    /**
     * Register plugin settings
     */
    public function register_settings() {
        register_setting(
            'bronnikov_sso_settings_group',
            'bronnikov_sso_settings',
            array( $this, 'sanitize_settings' )
        );

        add_settings_section(
            'bronnikov_sso_main_section',
            __( 'Connection Settings', 'bronnikov-sso' ),
            array( $this, 'render_section_description' ),
            'bronnikov-sso'
        );

        add_settings_field(
            'api_url',
            __( 'Platform API URL', 'bronnikov-sso' ),
            array( $this, 'render_api_url_field' ),
            'bronnikov-sso',
            'bronnikov_sso_main_section'
        );

        add_settings_field(
            'enabled',
            __( 'Enable SSO', 'bronnikov-sso' ),
            array( $this, 'render_enabled_field' ),
            'bronnikov-sso',
            'bronnikov_sso_main_section'
        );
    }

    /**
     * Sanitize settings before saving
     *
     * @param array $input Raw input values.
     * @return array Sanitized values.
     */
    public function sanitize_settings( $input ) {
        $sanitized = array();

        if ( isset( $input['api_url'] ) ) {
            $sanitized['api_url'] = esc_url_raw( $input['api_url'] );
        }

        if ( isset( $input['enabled'] ) ) {
            $sanitized['enabled'] = (bool) $input['enabled'];
        } else {
            $sanitized['enabled'] = false;
        }

        return $sanitized;
    }

    /**
     * Render settings section description
     */
    public function render_section_description() {
        echo '<p>' . esc_html__( 'Configure the connection to Bronnikov Platform for Single Sign-On.', 'bronnikov-sso' ) . '</p>';
    }

    /**
     * Render API URL field
     */
    public function render_api_url_field() {
        $settings = get_option( 'bronnikov_sso_settings', array() );
        $value = isset( $settings['api_url'] ) ? $settings['api_url'] : 'https://platform.bronnikov.com';
        ?>
        <input
            type="url"
            name="bronnikov_sso_settings[api_url]"
            value="<?php echo esc_attr( $value ); ?>"
            class="regular-text"
            placeholder="https://platform.bronnikov.com"
        />
        <p class="description">
            <?php esc_html_e( 'The base URL of your Bronnikov Platform installation.', 'bronnikov-sso' ); ?>
        </p>
        <?php
    }

    /**
     * Render enabled checkbox field
     */
    public function render_enabled_field() {
        $settings = get_option( 'bronnikov_sso_settings', array() );
        $checked = isset( $settings['enabled'] ) && $settings['enabled'];
        ?>
        <label>
            <input
                type="checkbox"
                name="bronnikov_sso_settings[enabled]"
                value="1"
                <?php checked( $checked ); ?>
            />
            <?php esc_html_e( 'Enable automatic Single Sign-On for users with valid JWT tokens', 'bronnikov-sso' ); ?>
        </label>
        <p class="description">
            <?php esc_html_e( 'When enabled, users logged into the Bronnikov Platform will be automatically logged into WordPress.', 'bronnikov-sso' ); ?>
        </p>
        <?php
    }

    /**
     * Render settings page
     */
    public function render_settings_page() {
        if ( ! current_user_can( 'manage_options' ) ) {
            return;
        }

        // Test connection if requested.
        $connection_status = null;
        if ( isset( $_GET['test_connection'] ) && check_admin_referer( 'bronnikov_sso_test_connection' ) ) {
            $api = new Bronnikov_API();
            $connection_status = $api->test_connection();
        }

        require_once BRONNIKOV_SSO_PLUGIN_DIR . 'admin/views/settings-page.php';
    }

    /**
     * Enqueue admin styles
     *
     * @param string $hook Current admin page hook.
     */
    public function enqueue_admin_styles( $hook ) {
        if ( 'settings_page_bronnikov-sso' !== $hook ) {
            return;
        }

        wp_enqueue_style(
            'bronnikov-sso-admin',
            BRONNIKOV_SSO_PLUGIN_URL . 'assets/css/admin.css',
            array(),
            BRONNIKOV_SSO_VERSION
        );
    }
}

// Initialize settings.
new Bronnikov_Settings();
