<?php
/**
 * Settings page template
 *
 * @package BronnikovSSO
 */

// Exit if accessed directly.
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}
?>

<div class="wrap bronnikov-sso-settings">
    <h1><?php echo esc_html( get_admin_page_title() ); ?></h1>

    <?php if ( isset( $_GET['settings-updated'] ) ) : ?>
        <div class="notice notice-success is-dismissible">
            <p><?php esc_html_e( 'Settings saved successfully.', 'bronnikov-sso' ); ?></p>
        </div>
    <?php endif; ?>

    <?php if ( null !== $connection_status ) : ?>
        <div class="notice notice-<?php echo $connection_status ? 'success' : 'error'; ?> is-dismissible">
            <p>
                <?php
                if ( $connection_status ) {
                    esc_html_e( '✓ Connection successful! Platform is reachable.', 'bronnikov-sso' );
                } else {
                    esc_html_e( '✗ Connection failed. Please check your API URL.', 'bronnikov-sso' );
                }
                ?>
            </p>
        </div>
    <?php endif; ?>

    <div class="bronnikov-sso-content">
        <div class="bronnikov-sso-main">
            <form method="post" action="options.php">
                <?php
                settings_fields( 'bronnikov_sso_settings_group' );
                do_settings_sections( 'bronnikov-sso' );
                submit_button();
                ?>
            </form>

            <div class="bronnikov-sso-test-connection">
                <h2><?php esc_html_e( 'Test Connection', 'bronnikov-sso' ); ?></h2>
                <p><?php esc_html_e( 'Click the button below to test the connection to the Bronnikov Platform.', 'bronnikov-sso' ); ?></p>
                <a
                    href="<?php echo esc_url( wp_nonce_url( add_query_arg( 'test_connection', '1' ), 'bronnikov_sso_test_connection' ) ); ?>"
                    class="button button-secondary"
                >
                    <?php esc_html_e( 'Test Connection', 'bronnikov-sso' ); ?>
                </a>
            </div>
        </div>

        <div class="bronnikov-sso-sidebar">
            <div class="bronnikov-sso-box">
                <h3><?php esc_html_e( 'About Bronnikov SSO', 'bronnikov-sso' ); ?></h3>
                <p><?php esc_html_e( 'This plugin enables Single Sign-On between your WordPress site and the Bronnikov Platform.', 'bronnikov-sso' ); ?></p>
                <p><?php esc_html_e( 'Users logged into the platform will be automatically logged into WordPress with the appropriate role based on their classification.', 'bronnikov-sso' ); ?></p>
            </div>

            <div class="bronnikov-sso-box">
                <h3><?php esc_html_e( 'Role Mapping', 'bronnikov-sso' ); ?></h3>
                <table class="widefat">
                    <thead>
                        <tr>
                            <th><?php esc_html_e( 'Platform Role', 'bronnikov-sso' ); ?></th>
                            <th><?php esc_html_e( 'WordPress Role', 'bronnikov-sso' ); ?></th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>Admin</td>
                            <td>Administrator</td>
                        </tr>
                        <tr>
                            <td>Manager, Curator</td>
                            <td>Editor</td>
                        </tr>
                        <tr>
                            <td>Center Director</td>
                            <td>Editor</td>
                        </tr>
                        <tr>
                            <td>Specialist, Expert</td>
                            <td>Contributor</td>
                        </tr>
                        <tr>
                            <td>Representative</td>
                            <td>Author</td>
                        </tr>
                        <tr>
                            <td>Client, Guest</td>
                            <td>Subscriber</td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <div class="bronnikov-sso-box">
                <h3><?php esc_html_e( 'Documentation', 'bronnikov-sso' ); ?></h3>
                <ul>
                    <li><a href="https://platform.bronnikov.com/docs" target="_blank"><?php esc_html_e( 'Platform Documentation', 'bronnikov-sso' ); ?></a></li>
                    <li><a href="https://platform.bronnikov.com/docs/sso" target="_blank"><?php esc_html_e( 'SSO Integration Guide', 'bronnikov-sso' ); ?></a></li>
                    <li><a href="https://github.com/bronnikov/platform" target="_blank"><?php esc_html_e( 'GitHub Repository', 'bronnikov-sso' ); ?></a></li>
                </ul>
            </div>
        </div>
    </div>
</div>
