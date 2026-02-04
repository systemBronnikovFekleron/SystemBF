<?php
/**
 * Authentication handler
 *
 * @package BronnikovSSO
 */

// Exit if accessed directly.
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * Class Bronnikov_Auth
 */
class Bronnikov_Auth {

    /**
     * Auto-login user if valid JWT token exists
     */
    public static function auto_login() {
        // Skip if already logged in.
        if ( is_user_logged_in() ) {
            return;
        }

        // Check if SSO is enabled.
        $settings = get_option( 'bronnikov_sso_settings', array() );
        if ( ! isset( $settings['enabled'] ) || ! $settings['enabled'] ) {
            return;
        }

        // Get JWT token from cookie.
        $token = isset( $_COOKIE['jwt_token'] ) ? sanitize_text_field( $_COOKIE['jwt_token'] ) : null;

        if ( ! $token ) {
            return;
        }

        // Validate token with Rails API.
        $api = new Bronnikov_API();
        $user_data = $api->validate_token( $token );

        if ( ! $user_data ) {
            return;
        }

        // Get or create WordPress user.
        $wp_user = self::get_or_create_user( $user_data );

        if ( ! $wp_user ) {
            return;
        }

        // Log user in.
        wp_set_current_user( $wp_user->ID );
        wp_set_auth_cookie( $wp_user->ID, true );

        // Trigger login action.
        do_action( 'wp_login', $wp_user->user_login, $wp_user );
    }

    /**
     * Get existing WordPress user or create new one
     *
     * @param array $user_data User data from Rails API.
     * @return WP_User|false WordPress user object or false on failure.
     */
    private static function get_or_create_user( $user_data ) {
        $email = sanitize_email( $user_data['email'] );

        // Try to find existing user by email.
        $user = get_user_by( 'email', $email );

        if ( $user ) {
            // Update user role based on classification.
            self::update_user_role( $user, $user_data['classification'] );

            // Update user meta.
            self::update_user_meta( $user->ID, $user_data );

            return $user;
        }

        // Create new user.
        $username = self::generate_username( $email );
        $password = wp_generate_password( 32, true, true );

        $user_id = wp_create_user( $username, $password, $email );

        if ( is_wp_error( $user_id ) ) {
            error_log( 'Bronnikov SSO: Failed to create user - ' . $user_id->get_error_message() );
            return false;
        }

        $user = get_user_by( 'id', $user_id );

        // Update user data.
        wp_update_user( array(
            'ID'         => $user_id,
            'first_name' => sanitize_text_field( $user_data['first_name'] ?? '' ),
            'last_name'  => sanitize_text_field( $user_data['last_name'] ?? '' ),
        ) );

        // Set user role.
        self::update_user_role( $user, $user_data['classification'] );

        // Store additional meta.
        self::update_user_meta( $user_id, $user_data );

        return $user;
    }

    /**
     * Update user role based on Rails classification
     *
     * @param WP_User $user WordPress user object.
     * @param string  $classification Rails classification.
     */
    private static function update_user_role( $user, $classification ) {
        $role = self::map_classification_to_role( $classification );

        if ( $role ) {
            $user->set_role( $role );
        }
    }

    /**
     * Map Rails classification to WordPress role
     *
     * @param string $classification Rails user classification.
     * @return string WordPress role.
     */
    private static function map_classification_to_role( $classification ) {
        $mapping = array(
            'admin'           => 'administrator',
            'manager'         => 'editor',
            'curator'         => 'editor',
            'center_director' => 'editor',
            'specialist'      => 'contributor',
            'expert'          => 'contributor',
            'instructor_1'    => 'contributor',
            'instructor_2'    => 'contributor',
            'instructor_3'    => 'contributor',
            'representative'  => 'author',
            'trainee'         => 'subscriber',
            'club_member'     => 'subscriber',
            'client'          => 'subscriber',
            'guest'           => 'subscriber',
        );

        return isset( $mapping[ $classification ] ) ? $mapping[ $classification ] : 'subscriber';
    }

    /**
     * Update user meta with Rails data
     *
     * @param int   $user_id WordPress user ID.
     * @param array $user_data User data from Rails.
     */
    private static function update_user_meta( $user_id, $user_data ) {
        update_user_meta( $user_id, 'bronnikov_user_id', intval( $user_data['id'] ) );
        update_user_meta( $user_id, 'bronnikov_classification', sanitize_text_field( $user_data['classification'] ) );
        update_user_meta( $user_id, 'bronnikov_last_sync', time() );
    }

    /**
     * Generate unique username from email
     *
     * @param string $email Email address.
     * @return string Unique username.
     */
    private static function generate_username( $email ) {
        $username = sanitize_user( substr( $email, 0, strpos( $email, '@' ) ) );

        // Ensure uniqueness.
        $counter = 1;
        $base_username = $username;

        while ( username_exists( $username ) ) {
            $username = $base_username . $counter;
            $counter++;
        }

        return $username;
    }
}
