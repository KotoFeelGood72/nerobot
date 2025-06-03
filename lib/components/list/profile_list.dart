import 'package:flutter/material.dart';

class ProfileOption {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  ProfileOption({
    required this.title,
    this.subtitle,
    this.onTap,
  });
}

class ProfileList extends StatelessWidget {
  final List<ProfileOption> options;

  const ProfileList({
    Key? key,
    required this.options,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: options.length,
        separatorBuilder: (context, index) => _buildDivider(),
        itemBuilder: (context, index) {
          final option = options[index];
          return _buildProfileOption(context, option);
        },
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, ProfileOption option) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            option.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          if (option.subtitle != null)
            Text(
              option.subtitle!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
        ],
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: option.onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      thickness: 1,
      color: Color(0xFFEEEEEE),
      height: 1,
    );
  }
}
